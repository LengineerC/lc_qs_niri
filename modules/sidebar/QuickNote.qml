pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.common

Rectangle {
    id: root

    property alias text: editor.text
    property bool previewMode: false
    property bool renaming: false

    property bool directoryReady: false
    property bool initialized: false
    property bool initialSelectionDone: false
    property bool dirty: false
    property bool saving: false

    property bool confirmingDelete: false

    property string deleteTargetFileName: ""
    property string deleteTargetPath: ""

    property int editorHeight: Appearance.px(500)
    readonly property int outlineWidth: Math.max(1, Math.round(Appearance.px(1)))

    property string currentFileName: ""
    property string currentPath: ""
    property string operationError: ""

    property string pendingAction: ""
    property var pendingActionData: ({})

    property string createTargetFileName: ""
    property string createTargetPath: ""

    property string renameOldFileName: ""
    property string renameOldPath: ""
    property string renameTargetFileName: ""
    property string renameTargetPath: ""

    property string savingPath: ""
    property string savingText: ""

    readonly property string notesDirectory:
        ShellSettings.stateDirectory + "/quicknote"

    readonly property url notesDirectoryUrl:
        "file://" + root.notesDirectory

    readonly property bool fileOperationRunning:
        ensureDirectoryProcess.running
        || createProcess.running
        || renameProcess.running
        || deleteProcess.running

    readonly property string statusText: {
        if (operationError.length > 0)
            return operationError;

        if (confirmingDelete)
            return I18n.tr("deleteNoteConfirm");

        if (!directoryReady)
            return I18n.tr("loading");

        if (createProcess.running
                || renameProcess.running
                || deleteProcess.running) {
            return I18n.tr("working");
        }

        if (!initialized)
            return I18n.tr("loading");

        if (saving)
            return I18n.tr("saving");

        if (dirty)
            return I18n.tr("unsaved");

        return I18n.tr("saved");
    }

    Layout.fillWidth: true

    implicitHeight:
        content.implicitHeight + Appearance.px(28)

    radius: Appearance.smallRadius
    color: Appearance.layer3

    border.width: 1
    border.color: Appearance.outline

    /*
     * 将单个数字补齐为两位。
     */
    function pad2(value: int): string {
        return value < 10
            ? "0" + value
            : String(value);
    }

    /*
     * 默认文件名：
     *
     * 2026_07_31_18_25_42.md
     */
    function defaultFileName(): string {
        const now = new Date();

        return now.getFullYear()
            + "_" + pad2(now.getMonth() + 1)
            + "_" + pad2(now.getDate())
            + "_" + pad2(now.getHours())
            + "_" + pad2(now.getMinutes())
            + "_" + pad2(now.getSeconds())
            + ".md";
    }

    function normalizePath(value): string {
        let path = String(value ?? "");

        if (path.startsWith("file://")) {
            path = path.slice(7);

            try {
                path = decodeURIComponent(path);
            } catch (error) {
                console.warn(
                    "Failed to decode note path:",
                    path,
                    error
                );
            }
        }

        return path;
    }

    function displayFileName(
            fileName,
            compact: bool): string {
        const name = String(fileName ?? "");

        const match =
            /^(\d{4})_(\d{2})_(\d{2})_(\d{2})_(\d{2})_(\d{2})(?:_(\d+))?\.md$/i
                .exec(name);

        if (!match)
            return name.replace(/\.md$/i, "");

        const duplicateSuffix = match[7]
            ? " #" + match[7]
            : "";

        if (compact) {
            return match[2]
                + "-" + match[3]
                + " " + match[4]
                + ":" + match[5]
                + duplicateSuffix;
        }

        return match[1]
            + "-" + match[2]
            + "-" + match[3]
            + " " + match[4]
            + ":" + match[5]
            + ":" + match[6]
            + duplicateSuffix;
    }

    /*
     * 检查 FolderListModel 中是否已有指定文件。
     */
    function fileNameExists(fileName: string): bool {
        for (let index = 0;
                index < noteFolderModel.count;
                index++) {
            if (noteFolderModel.get(index, "fileName")
                    === fileName) {
                return true;
            }
        }

        return false;
    }

    /*
     * 同一秒内连续新建笔记时避免文件名冲突。
     *
     * 例如：
     * 2026_07_31_18_25_42.md
     * 2026_07_31_18_25_42_2.md
     */
    function uniqueFileName(fileName: string): string {
        if (!fileNameExists(fileName))
            return fileName;

        const dotIndex = fileName.lastIndexOf(".");
        const stem = dotIndex >= 0
            ? fileName.slice(0, dotIndex)
            : fileName;

        const suffix = dotIndex >= 0
            ? fileName.slice(dotIndex)
            : ".md";

        let index = 2;
        let candidate = stem + "_" + index + suffix;

        while (fileNameExists(candidate)) {
            index++;
            candidate = stem + "_" + index + suffix;
        }

        return candidate;
    }

    /*
     * 清理用户输入的文件名。
     */
    function normalizeFileName(value): string {
        let fileName = String(value ?? "").trim();

        fileName = fileName.replace(
            /[\/\\\u0000\r\n\t]/g,
            "_"
        );

        /*
         * 不允许生成隐藏文件或 "."、".."。
         */
        fileName = fileName.replace(/^\.+/, "");

        /*
         * 避免文件名过长。
         */
        if (fileName.length > 180)
            fileName = fileName.slice(0, 180);

        if (fileName.length === 0)
            return "";

        if (!fileName.toLowerCase().endsWith(".md"))
            fileName += ".md";

        return fileName;
    }

    /*
     * 让 FolderListModel 重新读取目录。
     */
    function refreshFolderModel(): void {
        noteFolderModel.folder = "";

        Qt.callLater(() => {
            if (root.directoryReady)
                noteFolderModel.folder =
                    root.notesDirectoryUrl;
        });
    }

    /*
     * 用户输入后延迟保存。
     */
    function scheduleSave(): void {
        if (!root.initialized
                || root.currentPath.length === 0) {
            return;
        }

        root.operationError = "";
        root.dirty = true;

        if (!root.saving)
            saveTimer.restart();
    }

    function saveNow(): void {
        if (!root.initialized
                || root.currentPath.length === 0) {
            return;
        }

        if (root.saving)
            return;

        if (!root.dirty) {
            root.executePendingAction();
            return;
        }

        saveTimer.stop();

        /*
        * 记录这一次实际写入的文件和文本。
        * 后续可以判断保存期间是否又发生了编辑。
        */
        root.savingPath = root.currentPath;
        root.savingText = editor.text;

        root.dirty = false;
        root.saving = true;

        noteFile.setText(root.savingText);
    }

    /*
     * 保存当前文件，然后执行切换、新建或重命名操作。
     */
    function runAfterSave(
            action: string,
            data): void {
        pendingAction = action;
        pendingActionData = data ?? ({});

        saveTimer.stop();

        if (saving)
            return;

        if (dirty) {
            saveNow();
        } else {
            executePendingAction();
        }
    }

    function executePendingAction(): void {
        if (saving
                || dirty
                || pendingAction.length === 0) {
            return;
        }

        const action = pendingAction;
        const data = pendingActionData;

        pendingAction = "";
        pendingActionData = ({});

        switch (action) {
        case "open":
            performOpen(data);
            break;

        case "create":
            performCreate();
            break;

        case "rename":
            performRename(data);
            break;

        case "delete":
            performDelete(data);
            break;
        }
    }

    /*
     * 请求打开文件。
     */
    function requestOpen(fileName: string, filePath): void {
        const normalizedPath =
            root.normalizePath(filePath);

        if (normalizedPath.length === 0
                || root.samePath(
                    normalizedPath,
                    root.currentPath
                )) {
            return;
        }

        root.runAfterSave("open", {
            fileName: String(fileName),
            filePath: normalizedPath
        });
    }

    function performOpen(data): void {
        if (!data
                || !data.fileName
                || !data.filePath) {
            return;
        }

        root.confirmingDelete = false;
        root.operationError = "";
        root.initialized = false;
        root.dirty = false;

        root.currentFileName =
            String(data.fileName);

        root.currentPath =
            root.normalizePath(data.filePath);

        renameEditor.text =
            root.currentFileName;
    }

    /*
     * 请求新建文件。
     */
    function requestNewNote(): void {
        if (!directoryReady
                || createProcess.running
                || renameProcess.running) {
            return;
        }

        runAfterSave("create", {});
    }

    function performCreate(): void {
        const fileName = uniqueFileName(
            defaultFileName()
        );

        createTargetFileName = fileName;
        createTargetPath =
            notesDirectory + "/" + fileName;

        operationError = "";
        initialized = false;

        /*
         * set -C 开启 noclobber，避免意外覆盖
         * 已存在的同名文件。
         *
         * 路径通过 $1 传递，不会被当作 shell 代码解析。
         */
        createProcess.exec([
            "sh",
            "-c",
            "set -C; : > \"$1\"",
            "quicknote-create",
            createTargetPath
        ]);
    }

    /*
     * 开始修改文件名。
     */
    function beginRename(): void {
        if (!initialized
                || currentPath.length === 0
                || fileOperationRunning) {
            return;
        }

        root.confirmingDelete = false;
        operationError = "";
        renameEditor.text = currentFileName;
        renaming = true;

        Qt.callLater(() => {
            renameEditor.forceActiveFocus();
            renameEditor.selectAll();
        });
    }

    function cancelRename(): void {
        renaming = false;
        renameEditor.text = currentFileName;
        operationError = "";
    }

    function commitRename(): void {
        if (!renaming
                || currentPath.length === 0) {
            return;
        }

        const targetFileName =
            normalizeFileName(renameEditor.text);

        if (targetFileName.length === 0) {
            operationError =
                I18n.tr("invalidNoteName");
            return;
        }

        if (targetFileName === currentFileName) {
            cancelRename();
            return;
        }

        if (fileNameExists(targetFileName)) {
            operationError =
                I18n.tr("noteNameExists");
            return;
        }

        runAfterSave("rename", {
            oldFileName: currentFileName,
            oldPath: currentPath,
            targetFileName: targetFileName,
            targetPath:
                notesDirectory + "/" + targetFileName
        });
    }

    function performRename(data): void {
        if (!data
                || !data.oldPath
                || !data.targetPath) {
            return;
        }

        renameOldFileName = String(data.oldFileName);
        renameOldPath = String(data.oldPath);
        renameTargetFileName =
            String(data.targetFileName);
        renameTargetPath = String(data.targetPath);

        operationError = "";
        initialized = false;

        /*
         * 先检查目标文件是否存在，再执行 mv。
         *
         * $1 和 $2 是独立参数，因此文件名带空格也不会
         * 被拆分。
         */
        renameProcess.exec([
            "sh",
            "-c",
            "if [ -e \"$2\" ]; then "
                + "exit 17; "
                + "fi; "
                + "mv -- \"$1\" \"$2\"",
            "quicknote-rename",
            renameOldPath,
            renameTargetPath
        ]);
    }

    function togglePreviewMode(): void {
        if (!root.initialized)
            return;

        root.previewMode = !root.previewMode;

        if (root.previewMode) {
            editor.deselect();
            root.saveNow();
        } else {
            Qt.callLater(() => {
                editor.forceActiveFocus(
                    Qt.OtherFocusReason
                );
            });
        }
    }

    function requestDelete(): void {
        if (!root.initialized
                || root.currentPath.length === 0
                || root.fileOperationRunning) {
            return;
        }

        root.operationError = "";
        root.confirmingDelete = true;
    }

    function cancelDelete(): void {
        root.confirmingDelete = false;
    }

    function confirmDelete(): void {
        if (!root.confirmingDelete
                || root.currentPath.length === 0
                || root.fileOperationRunning) {
            return;
        }

        root.confirmingDelete = false;

        root.runAfterSave("delete", {
            fileName: root.currentFileName,
            filePath: root.currentPath
        });
    }

    function performDelete(data): void {
        if (!data || !data.filePath)
            return;

        const targetPath =
            root.normalizePath(data.filePath);

        /*
        * 只允许删除 quicknote 目录内的直接子文件。
        */
        const directoryPrefix =
            root.notesDirectory + "/";

        if (!targetPath.startsWith(directoryPrefix)
                || targetPath.slice(
                    directoryPrefix.length
                ).includes("/")) {
            root.operationError =
                I18n.tr("noteDeleteError");

            console.warn(
                "Refusing to delete path outside note directory:",
                targetPath
            );

            return;
        }

        root.deleteTargetFileName =
            String(data.fileName ?? "");

        root.deleteTargetPath = targetPath;
        root.operationError = "";

        deleteProcess.exec([
            "rm",
            "--",
            root.deleteTargetPath
        ]);
    }

    /*
     * 第一次加载目录时，打开最近修改的文件。
     * 如果目录为空，则自动创建第一份笔记。
     */
    function selectInitialNote(): void {
        if (initialSelectionDone
                || !directoryReady
                || noteFolderModel.status
                    !== FolderListModel.Ready) {
            return;
        }

        initialSelectionDone = true;

        if (noteFolderModel.count > 0) {
            performOpen({
                fileName: noteFolderModel.get(
                    0, "fileName"),
                filePath: noteFolderModel.get(
                    0, "filePath")
            });
        } else {
            requestNewNote();
        }
    }

    function stripFileProtocol(path): string {
        return String(path ?? "").replace(/^file:\/\//, "");
    }

    function samePath(a, b): bool {
        return stripFileProtocol(a) === stripFileProtocol(b);
    }

    readonly property int currentNoteIndex: {
        for (let index = 0; index < noteFolderModel.count; ++index) {
            if (samePath(noteFolderModel.get(index, "filePath"), currentPath))
                return index;
        }

        return -1;
    }

    readonly property string currentNoteDisplayName: {
        if (currentNoteIndex >= 0) {
            return displayFileName(
                noteFolderModel.get(currentNoteIndex, "fileName"),
                false
            );
        }

        if (noteFolderModel.count > 0) {
            return displayFileName(
                noteFolderModel.get(0, "fileName"),
                false
            );
        }

        return I18n.tr("noNotes");
    }

    Component.onCompleted: {
        ensureDirectoryProcess.exec([
            "mkdir",
            "-p",
            "--",
            root.notesDirectory
        ]);
    }

    onVisibleChanged: {
        if (!visible)
            saveNow();
    }

    FolderListModel {
        id: noteFolderModel

        folder: ""
        nameFilters: ["*.md", "*.MD"]

        showDirs: false
        showFiles: true
        showHidden: false
        showDotAndDotDot: false
        showOnlyReadable: true

        sortField: FolderListModel.Time
        sortReversed: true

        onStatusChanged: {
            if (status === FolderListModel.Ready)
                Qt.callLater(root.selectInitialNote);
        }
    }

    Process {
        id: ensureDirectoryProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.directoryReady = true;
                root.operationError = "";
                root.refreshFolderModel();
            } else {
                root.directoryReady = false;
                root.operationError =
                    I18n.tr("noteDirectoryError");

                console.warn(
                    "Failed to create quick-note directory:",
                    root.notesDirectory,
                    exitCode,
                    exitStatus
                );
            }
        }
    }

    Process {
        id: createProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.operationError = "";

                root.performOpen({
                    fileName:
                        root.createTargetFileName,
                    filePath:
                        root.createTargetPath
                });

                root.refreshFolderModel();
            } else {
                root.initialized =
                    root.currentPath.length > 0;

                root.operationError =
                    I18n.tr("noteCreateError");

                console.warn(
                    "Failed to create quick note:",
                    root.createTargetPath,
                    exitCode,
                    exitStatus
                );

                root.refreshFolderModel();
            }
        }
    }

    Process {
        id: renameProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.operationError = "";
                root.currentFileName =
                    root.renameTargetFileName;
                root.currentPath =
                    root.renameTargetPath;

                renameEditor.text =
                    root.renameTargetFileName;

                root.renaming = false;
                root.dirty = false;

                /*
                 * currentPath 改变后 FileView 会加载
                 * 重命名后的文件。
                 */
                root.initialized = false;

                root.refreshFolderModel();
            } else {
                root.initialized = true;

                if (exitCode === 17) {
                    root.operationError =
                        I18n.tr("noteNameExists");
                } else {
                    root.operationError =
                        I18n.tr("noteRenameError");
                }

                renameEditor.text =
                    root.renameOldFileName;

                console.warn(
                    "Failed to rename quick note:",
                    root.renameOldPath,
                    "->",
                    root.renameTargetPath,
                    exitCode,
                    exitStatus
                );

                root.refreshFolderModel();
            }
        }
    }

    Process {
        id: deleteProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.operationError = "";
                root.confirmingDelete = false;

                /*
                * 先禁用初始化状态，避免清空编辑器时
                * 被 onTextChanged 识别为用户修改。
                */
                root.initialized = false;
                root.dirty = false;
                root.saving = false;
                root.renaming = false;

                root.currentFileName = "";
                root.currentPath = "";

                editor.text = "";
                renameEditor.text = "";

                /*
                * 允许 selectInitialNote() 再运行一次：
                *
                * - 尚有文件：打开最新的一份
                * - 没有文件：自动新建一份
                */
                root.initialSelectionDone = false;
                root.refreshFolderModel();
            } else {
                /*
                * 删除失败时继续保留当前文件和编辑内容。
                */
                root.initialized =
                    root.currentPath.length > 0;

                root.confirmingDelete = false;
                root.operationError =
                    I18n.tr("noteDeleteError");

                console.warn(
                    "Failed to delete quick note:",
                    root.deleteTargetPath,
                    exitCode,
                    exitStatus
                );

                root.refreshFolderModel();
            }
        }
    }

    FileView {
        id: noteFile

        path: root.currentPath
        atomicWrites: true
        printErrors: false
        watchChanges: false

        onLoaded: {
            /*
             * 在赋值前保持 initialized=false，
             * 避免把加载文件误判为用户修改。
             */
            root.initialized = false;

            editor.text = noteFile.text();

            root.dirty = false;
            root.saving = false;
            root.operationError = "";
            root.initialized = true;

            renameEditor.text =
                root.currentFileName;
        }

        onLoadFailed: error => {
            root.saving = false;
            root.savingPath = "";
            root.savingText = "";
            saveTimer.stop();

            if (root.currentPath.length === 0)
                return;

            root.initialized = false;
            root.dirty = false;

            root.operationError =
                I18n.tr("noteLoadError");

            console.warn(
                "Failed to load quick note:",
                root.currentPath,
                error
            );
        }

        onSaved: {
            const savedPath = root.savingPath;
            const savedText = root.savingText;

            root.saving = false;
            root.savingPath = "";
            root.savingText = "";
            root.operationError = "";

            /*
            * 正常情况下保存过程中不会切换 path。
            * 加这个检查可以防止异步结果污染新文件状态。
            */
            if (!root.samePath(
                    savedPath,
                    root.currentPath)) {
                return;
            }

            /*
            * 保存期间编辑器内容发生变化，说明磁盘中的内容
            * 已经落后，需要再保存一次。
            */
            root.dirty = editor.text !== savedText;

            if (root.pendingAction.length > 0) {
                /*
                * 文件切换、重命名、删除等操作正在等待，
                * 此时必须立即保存最新内容。
                */
                if (root.dirty) {
                    Qt.callLater(root.saveNow);
                } else {
                    root.executePendingAction();
                }
            } else if (root.dirty) {
                /*
                * 普通输入继续走 700ms 防抖，
                * 不再形成连续写入循环。
                */
                saveTimer.restart();
            }
        }

        onSaveFailed: error => {
            root.saving = false;
            root.savingPath = "";
            root.savingText = "";
            root.dirty = true;

            saveTimer.stop();

            root.pendingAction = "";
            root.pendingActionData = ({});

            root.operationError =
                I18n.tr("noteSaveError");

            console.warn(
                "Failed to save quick note:",
                root.currentPath,
                error
            );
        }
    }

    Timer {
        id: saveTimer

        interval: 700
        repeat: false
        onTriggered: root.saveNow()
    }

    ColumnLayout {
        id: content

        anchors {
            fill: parent
            margins: Appearance.px(14)
        }

        spacing: Appearance.px(12)

        /*
         * 标题栏
         */
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.px(5)

            Text {
                text: "󰠮"
                color: Appearance.primary

                font {
                    family:
                        Appearance.iconFontFamily
                    pixelSize: Appearance.px(28)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.px(1)

                Text {
                    Layout.fillWidth: true

                    text: I18n.tr("quickNote")
                    color: Appearance.layer0Text
                    elide: Text.ElideRight

                    font {
                        family:
                            Appearance.fontFamily
                        pixelSize:
                            Appearance.largeFontSize
                        weight: Font.DemiBold
                    }
                }

                Text {
                    Layout.fillWidth: true

                    text: root.currentFileName.length > 0
                        ? root.statusText
                            + " · "
                            + root.currentFileName
                        : root.statusText

                    color: root.dirty
                            || root.operationError.length > 0
                        ? Appearance.primary
                        : Appearance.subtext

                    elide: Text.ElideMiddle

                    font {
                        family:
                            Appearance.fontFamily
                        pixelSize:
                            Appearance.smallFontSize
                    }
                }
            }

            HeaderButton {
                /*
                 * file-plus
                 */
                icon: "󰈔"

                enabled: root.directoryReady
                    && !root.confirmingDelete
                    && !root.fileOperationRunning

                onClicked: root.requestNewNote()
            }

            HeaderButton {
                /*
                 * rename
                 */
                icon: "󰑕"

                enabled: root.initialized
                    && root.currentPath.length > 0
                    && !root.confirmingDelete
                    && !root.fileOperationRunning

                onClicked: root.beginRename()
            }

            HeaderButton {
                visible: !root.confirmingDelete
                icon: "󰆴"

                enabled: root.initialized
                    && root.currentPath.length > 0
                    && !root.fileOperationRunning

                onClicked: root.requestDelete()
            }

            HeaderButton {
                /*
                * 确认删除
                */
                visible: root.confirmingDelete
                icon: "󰄬"

                enabled: !root.fileOperationRunning

                onClicked: root.confirmDelete()
            }

            HeaderButton {
                /*
                * 取消删除
                */
                visible: root.confirmingDelete
                icon: "󰅖"

                enabled: !root.fileOperationRunning

                onClicked: root.cancelDelete()
            }
        }

        /*
         * 重命名输入框
         */
        RowLayout {
            Layout.fillWidth: true
            visible: root.renaming
            spacing: Appearance.px(7)

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Appearance.px(38)

                radius: Appearance.smallRadius
                color: Appearance.layer2

                border.width: 1
                border.color:
                    renameEditor.activeFocus
                        ? Appearance.primary
                        : Appearance.outline

                TextInput {
                    id: renameEditor

                    anchors {
                        fill: parent
                        leftMargin: Appearance.px(11)
                        rightMargin: Appearance.px(11)
                    }

                    verticalAlignment:
                        TextInput.AlignVCenter

                    color: Appearance.layer0Text
                    selectionColor:
                        Appearance.primary
                    selectedTextColor:
                        Appearance.primaryText

                    selectByMouse: true
                    clip: true

                    font {
                        family:
                            Appearance.monospaceFontFamily
                        pixelSize:
                            Appearance.fontSize
                    }

                    onAccepted:
                        root.commitRename()

                    Keys.onPressed: event => {
                        if (event.key
                                === Qt.Key_Escape) {
                            root.cancelRename();
                            event.accepted = true;
                        }
                    }
                }
            }

            HeaderButton {
                icon: "󰄬"
                onClicked: root.commitRename()
            }

            HeaderButton {
                icon: "󰅖"
                onClicked: root.cancelRename()
            }
        }

        /*
         * 文件列表
         */
        Rectangle {
            id: noteSelectorBox

            Layout.fillWidth: true
            implicitHeight: Appearance.px(44)

            radius: Appearance.smallRadius
            color: Appearance.layer2

            border.width: 1
            border.color: Appearance.outline

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.px(10)
                    rightMargin: Appearance.px(10)
                }

                spacing: Appearance.px(8)

                Text {
                    text: "󰈙"
                    color: Appearance.subtext

                    font {
                        family:
                            Appearance.iconFontFamily
                        pixelSize: Appearance.px(16)
                    }
                }

                Rectangle {
                    id: selectorButton

                    Layout.fillWidth: true
                    Layout.preferredHeight:
                        Appearance.px(32)

                    radius: Appearance.smallRadius

                    color: selectorMouse.containsMouse
                        || noteSelectorPopup.opened
                            ? Appearance.layer1Active
                            : "transparent"

                    Text {
                        anchors {
                            left: parent.left
                            right: dropIcon.left
                            verticalCenter:
                                parent.verticalCenter

                            leftMargin:
                                Appearance.px(10)

                            rightMargin:
                                Appearance.px(8)
                        }

                        text: root.currentNoteDisplayName

                        color: root.currentFileName.length > 0
                            ? Appearance.layer0Text
                            : Appearance.subtext

                        elide: Text.ElideMiddle
                        verticalAlignment:
                            Text.AlignVCenter

                        font {
                            family:
                                Appearance.monospaceFontFamily
                            pixelSize:
                                Appearance.fontSize
                        }
                    }

                    Text {
                        id: dropIcon

                        anchors {
                            right: parent.right
                            rightMargin:
                                Appearance.px(9)

                            verticalCenter:
                                parent.verticalCenter
                        }

                        text: noteSelectorPopup.opened
                            ? "󰅀"
                            : "󰅂"

                        color: Appearance.subtext

                        font {
                            family:
                                Appearance.iconFontFamily
                            pixelSize:
                                Appearance.px(15)
                        }
                    }

                    MouseArea {
                        id: selectorMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        enabled: root.directoryReady
                            && noteFolderModel.count > 0
                            && !root.fileOperationRunning

                        cursorShape: enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor

                        onClicked: {
                            if (noteSelectorPopup.opened) {
                                noteSelectorPopup.close();
                            } else {
                                noteSelectorPopup.open();
                            }
                        }
                    }
                }

                Text {
                    text: String(noteFolderModel.count)
                    visible: noteFolderModel.count > 0
                    color: Appearance.subtext

                    font {
                        family: Appearance.fontFamily
                        pixelSize:
                            Appearance.smallFontSize
                    }
                }
            }

            Controls.Popup {
                id: noteSelectorPopup

                /*
                * 将 selectorButton 作为 parent，
                * CloseOnPressOutsideParent 点击选择框时不会
                * 抢先关闭 Popup。
                */
                parent: selectorButton

                x: 0
                y: selectorButton.height
                    + Appearance.px(6)

                width: selectorButton.width
                padding: Appearance.px(6)

                modal: false
                focus: true

                closePolicy:
                    Controls.Popup.CloseOnEscape
                    | Controls.Popup.CloseOnPressOutsideParent

                background: Rectangle {
                    radius: Appearance.smallRadius
                    color: Appearance.layer2

                    border.width: 1
                    border.color: Appearance.outline
                }

                contentItem: ListView {
                    id: noteSelectorList

                    readonly property real rowHeight:
                        Appearance.px(36)

                    implicitHeight: Math.min(
                        noteFolderModel.count
                            * (rowHeight + spacing),
                        Appearance.px(220)
                    )

                    model: noteFolderModel
                    spacing: Appearance.px(4)

                    clip: true
                    boundsBehavior:
                        Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: noteOption

                        required property int index
                        required property string fileName
                        required property url filePath

                        readonly property bool selected:
                            root.samePath(
                                noteOption.filePath,
                                root.currentPath
                            )

                        width: noteSelectorList.width
                        height: noteSelectorList.rowHeight

                        /*
                        * 不用 fullRadius，避免变成胶囊形。
                        */
                        radius: Appearance.smallRadius

                        color: noteOption.selected
                            ? Appearance.primaryContainer
                            : optionMouse.containsMouse
                                ? Appearance.layer1Active
                                : "transparent"

                        Text {
                            anchors {
                                fill: parent
                                leftMargin:
                                    Appearance.px(11)
                                rightMargin:
                                    Appearance.px(11)
                            }

                            text: root.displayFileName(
                                noteOption.fileName,
                                false
                            )

                            color: noteOption.selected
                                ? Appearance.primaryContainerText
                                : Appearance.layer0Text

                            elide: Text.ElideMiddle
                            verticalAlignment:
                                Text.AlignVCenter

                            font {
                                family:
                                    Appearance.monospaceFontFamily
                                pixelSize:
                                    Appearance.fontSize
                            }
                        }

                        MouseArea {
                            id: optionMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked: {
                                noteSelectorPopup.close();

                                /*
                                * 点击当前文件只关闭菜单，
                                * 不重复加载文件。
                                */
                                if (!noteOption.selected) {
                                    root.requestOpen(
                                        noteOption.fileName,
                                        String(noteOption.filePath)
                                    );
                                }
                            }
                        }
                    }

                    Controls.ScrollBar.vertical:
                        Controls.ScrollBar {
                            policy:
                                Controls.ScrollBar.AsNeeded
                        }
                }
            }
        }

        /*
         * 编辑器及预览
         */
        Rectangle {
            id: noteContainer

            Layout.fillWidth: true
            Layout.preferredHeight: root.editorHeight

            radius: Appearance.smallRadius

            // 外层本身就是边框。
            color: editor.activeFocus
                ? Appearance.primary
                : Appearance.outline

            antialiasing: true

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.fastDuration
                }
            }

            Rectangle {
                id: noteSurface

                readonly property real scrollBeyondLastLine:
                    Math.max(
                        Appearance.px(80),
                        height * 0.38
                    )

                anchors.fill: parent
                anchors.margins: root.outlineWidth

                radius: Math.max(
                    0,
                    noteContainer.radius
                        - root.outlineWidth
                )

                color: Appearance.layer2
                clip: true

                Flickable {
                    id: editorFlickable

                    anchors.fill: parent
                    visible: !root.previewMode

                    contentWidth: width
                    contentHeight: Math.max(
                        height,
                        editor.y
                            + editor.implicitHeight
                            + noteSurface.scrollBeyondLastLine
                    )

                    boundsBehavior:
                        Flickable.StopAtBounds

                    clip: true

                    TextEdit {
                        id: editor

                        x: Appearance.px(12)
                        y: Appearance.px(10)

                        width: Math.max(
                            0,
                            editorFlickable.width
                                - Appearance.px(24)
                        )

                        height: Math.max(
                            implicitHeight,
                            editorFlickable.height
                                - Appearance.px(20)
                        )

                        enabled: root.initialized
                            && root.currentPath.length > 0

                        textFormat: TextEdit.PlainText
                        wrapMode: TextEdit.Wrap

                        color: Appearance.layer0Text
                        selectionColor: Appearance.primary
                        selectedTextColor:
                            Appearance.primaryText

                        selectByMouse: true
                        persistentSelection: true
                        activeFocusOnPress: true
                        focus: !root.previewMode

                        font {
                            family:
                                Appearance.monospaceFontFamily
                            pixelSize: Appearance.fontSize
                        }

                        onTextChanged:
                            root.scheduleSave()

                        onActiveFocusChanged: {
                            if (!activeFocus)
                                root.saveNow();
                        }

                        Keys.onPressed: event => {
                            const controlPressed =
                                event.modifiers
                                    & Qt.ControlModifier;

                            if (controlPressed
                                    && event.key
                                        === Qt.Key_S) {
                                root.saveNow();
                                event.accepted = true;
                            }
                        }
                    }

                    Text {
                        anchors {
                            left: parent.left
                            top: parent.top
                            leftMargin: Appearance.px(12)
                            topMargin: Appearance.px(10)
                        }

                        visible: root.initialized
                            && editor.text.length === 0
                            && !editor.preeditText

                        text: I18n.tr(
                            "markdownNotePlaceholder"
                        )

                        color: Appearance.subtext

                        font {
                            family:
                                Appearance.monospaceFontFamily
                            pixelSize: Appearance.fontSize
                        }
                    }
                }

                Flickable {
                    id: previewFlickable

                    anchors.fill: parent
                    visible: root.previewMode

                    contentWidth: width
                    contentHeight: Math.max(
                        height,
                        previewText.y
                            + previewText.implicitHeight
                            + noteSurface.scrollBeyondLastLine
                    )

                    boundsBehavior:
                        Flickable.StopAtBounds

                    clip: true

                    Text {
                        id: previewText

                        x: Appearance.px(12)
                        y: Appearance.px(10)

                        width: Math.max(
                            0,
                            previewFlickable.width
                                - Appearance.px(24)
                        )

                        text: editor.text.length > 0
                            ? editor.text
                            : I18n.tr("emptyNote")

                        textFormat: Text.MarkdownText
                        wrapMode: Text.Wrap

                        color: editor.text.length > 0
                            ? Appearance.layer0Text
                            : Appearance.subtext

                        linkColor: Appearance.primary

                        font {
                            family: Appearance.fontFamily
                            pixelSize: Appearance.fontSize
                        }

                        onLinkActivated: link =>
                            Qt.openUrlExternally(link)
                    }
                }

                Rectangle {
                    id: floatingModeButton

                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                        rightMargin: Appearance.px(7)
                        bottomMargin: Appearance.px(7)
                    }

                    width: Appearance.px(28)
                    height: Appearance.px(28)
                    z: 100

                    radius: Appearance.fullRadius
                    color: Appearance.layer3

                    border.width: 1
                    border.color: root.previewMode
                        ? Appearance.primary
                        : Appearance.outline

                    /*
                    * 平时保持低透明度，悬停时变清晰。
                    */
                    opacity: !root.initialized
                        ? 0.25
                        : modeButtonMouse.containsMouse
                            ? 0.9
                            : 0.48

                    scale: modeButtonMouse.pressed
                        ? 0.86
                        : 1

                    Text {
                        anchors.centerIn: parent

                        text: root.previewMode
                            ? "󰏫"
                            : "󰈈"

                        color: root.previewMode
                            ? Appearance.primary
                            : Appearance.layer0Text

                        font {
                            family: Appearance.iconFontFamily
                            pixelSize: Appearance.px(15)
                        }
                    }

                    MouseArea {
                        id: modeButtonMouse

                        anchors.fill: parent
                        enabled: root.initialized
                        hoverEnabled: true

                        cursorShape: enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor

                        onClicked:
                            root.togglePreviewMode()
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Appearance.fastDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Appearance.fastDuration
                        }
                    }
                }
            }
        }
    }

    component HeaderButton: Rectangle {
        id: button

        required property string icon

        signal clicked

        implicitWidth: Appearance.px(34)
        implicitHeight: Appearance.px(34)

        radius: Appearance.fullRadius

        color: buttonMouse.containsMouse
                && button.enabled
            ? Appearance.layer1Active
            : "transparent"

        scale: buttonMouse.pressed
            ? 0.88
            : 1

        opacity: button.enabled
            ? 1
            : 0.35

        Text {
            anchors.centerIn: parent

            text: button.icon
            color: Appearance.layer0Text

            font {
                family:
                    Appearance.iconFontFamily
                pixelSize: Appearance.px(18)
            }
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true

            cursorShape: enabled
                ? Qt.PointingHandCursor
                : Qt.ArrowCursor

            onClicked: button.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration:
                    Appearance.fastDuration
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration:
                    Appearance.fastDuration

                easing.type:
                    Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration:
                    Appearance.fastDuration
            }
        }
    }
}
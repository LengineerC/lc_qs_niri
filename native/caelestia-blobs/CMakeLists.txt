cmake_minimum_required(VERSION 3.19)

project(test-caelestia-blobs LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.9 REQUIRED COMPONENTS Core Qml Quick ShaderTools)
qt_standard_project_setup(REQUIRES 6.9)

get_filename_component(
    CAELESTIA_BLOBS_SOURCE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../caelestiashell/plugin/src/Caelestia/Blobs"
    ABSOLUTE
)

get_filename_component(
    CAELESTIA_BLOBS_MODULE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/../../Caelestia/Blobs"
    ABSOLUTE
)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

qt_add_qml_module(test-caelestia-blobs
    URI Caelestia.Blobs
    OUTPUT_DIRECTORY "${CAELESTIA_BLOBS_MODULE_DIR}"
    SOURCES
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobgroup.cpp"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobgroup.hpp"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobshape.cpp"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobshape.hpp"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobrect.cpp"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobrect.hpp"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobinvertedrect.cpp"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobinvertedrect.hpp"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobmaterial.cpp"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/blobmaterial.hpp"
)

target_link_libraries(test-caelestia-blobs PRIVATE Qt6::Core Qt6::Qml Qt6::Quick)
target_include_directories(test-caelestia-blobs PRIVATE "${CAELESTIA_BLOBS_SOURCE_DIR}")
set_target_properties(test-caelestia-blobs PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CAELESTIA_BLOBS_MODULE_DIR}"
)
set_target_properties(test-caelestia-blobsplugin PROPERTIES
    BUILD_RPATH "\$ORIGIN"
    INSTALL_RPATH "\$ORIGIN"
    LIBRARY_OUTPUT_DIRECTORY "${CAELESTIA_BLOBS_MODULE_DIR}"
)

qt_add_shaders(test-caelestia-blobs "blob_shaders"
    BASE "${CAELESTIA_BLOBS_SOURCE_DIR}"
    BATCHABLE
    OPTIMIZED
    NOHLSL
    NOMSL
    GLSL "300es,330"
    PREFIX "/"
    FILES
        "${CAELESTIA_BLOBS_SOURCE_DIR}/shaders/blob.frag"
        "${CAELESTIA_BLOBS_SOURCE_DIR}/shaders/blob.vert"
)

cmake_minimum_required(VERSION 3.21)

project(VescDash VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Bluetooth)

# --------------------------------------------------------------------------
# libsimplebm (VESC BLE library)
# Expects the library to be available as a CMake package or via pkg-config.
# Clone it alongside this project: git submodule add <url> third_party/libsimplebm
# --------------------------------------------------------------------------
add_subdirectory(third_party/libsimplebm EXCLUDE_FROM_ALL)

# Signal to the BLE client that libsimplebm is available
target_compile_definitions(VescDash PRIVATE HAVE_LIBSIMPLEBM)

qt_standard_project_setup()

set(SOURCES
    main.cpp
    src/VescController.cpp
    src/VescBleClient.cpp
)

set(HEADERS
    src/VescController.h
    src/VescBleClient.h
)

set(QML_FILES
    qml/Main.qml
    qml/Gauge.qml
    qml/StatCard.qml
    qml/SettingsPage.qml
)

qt_add_executable(VescDash ${SOURCES} ${HEADERS})

qt_add_qml_module(VescDash
    URI VescDash
    VERSION 1.0
    QML_FILES ${QML_FILES}
)

target_include_directories(VescDash PRIVATE src)

target_link_libraries(VescDash
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Bluetooth
        simplebm          # target exported by libsimplebm
)

install(TARGETS VescDash
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# ── Unit tests ──────────────────────────────────────────────────────────────
enable_testing()
find_package(Qt6 REQUIRED COMPONENTS Test)

qt_add_executable(TestVescController tests/TestVescController.cpp src/VescController.cpp)
target_include_directories(TestVescController PRIVATE src)
target_link_libraries(TestVescController PRIVATE Qt6::Core Qt6::Test)
add_test(NAME TestVescController COMMAND TestVescController)

cmake_minimum_required(VERSION 3.21.1)

include(pico_sdk_import.cmake)
include(pico_extras_import.cmake)

project(sufni-suspension-telemetry)

set(PICO_BOARD pico_w)

set(CMAKE_C_STANDARD 11)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

pico_sdk_init()

add_executable(sufni-suspension-telemetry
    src/fw/main.c
    src/fs/microsd.c
    src/msc/msc_disk.c
    src/msc/sst_usb_descriptors.c
    src/net/tcpclient.c
    src/ntp/ntp.c
    src/pio_i2c/pio_i2c.c
    src/rtc/ds3231.c
    src/ui/pushbutton.c
    src/util/config.c
    src/util/list.c
)

pico_generate_pio_header(sufni-suspension-telemetry
    ${CMAKE_CURRENT_LIST_DIR}/src/pio_i2c/i2c.pio
)

add_subdirectory(external/no-OS-FatFS-SD-SPI-RPi-Pico/src firmware/external/no-OS-FatFS-SD-SPI-RPi-Pico/src)
add_subdirectory(external/pico-as5600 firmware/external/pico-as5600)
add_subdirectory(external/pico-ssd1306 firmware/external/pico-ssd1306)

if(${DISP_PROTO} STREQUAL SPI)
    target_compile_options(sufni-suspension-telemetry PUBLIC
        -DSPI_DISPLAY
    )
endif()

if(${SPI_MICROSD})
    target_compile_options(sufni-suspension-telemetry PUBLIC
        -DSPI_MICROSD
    )
endif()

target_include_directories(sufni-suspension-telemetry PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/src/msc
    ${CMAKE_CURRENT_LIST_DIR}/src/net
)

target_link_libraries(sufni-suspension-telemetry
    pico_stdlib
    pico_multicore
    pico_cyw43_arch_lwip_threadsafe_background
    pico_lwip_sntp
    hardware_adc
    hardware_sleep
    tinyusb_board
    tinyusb_device
    hardware_i2c
    hardware_pio
    hardware_rtc
    FatFs_SPI
    as5600
    ssd1306
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(sufni-suspension-telemetry PUBLIC
        -DSNTP_DEBUG=LWIP_DBG_ON)
    pico_enable_stdio_uart(sufni-suspension-telemetry 1)
endif()

pico_add_extra_outputs(sufni-suspension-telemetry)

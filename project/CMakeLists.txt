cmake_minimum_required(VERSION 3.13)

set(PROJECT_NAME cmakeProject)
project(${PROJECT_NAME} C ASM)

set(CMAKE_C_STANDARD 11)

# -----------------------------------------------------------------------------
#  Toolchain check
# -----------------------------------------------------------------------------
if(NOT CMAKE_TOOLCHAIN_FILE)
    message(WARNING "You should invoke CMake with -DCMAKE_TOOLCHAIN_FILE=<path/to/arm-toolchain.cmake>")
endif()

# -----------------------------------------------------------------------------
#  CPU / FPU / ABI flags
# -----------------------------------------------------------------------------
set(MCU_FLAGS
    -mcpu=cortex-m4
    -mthumb
    -mfpu=fpv4-sp-d16
    -mfloat-abi=hard
    # -Oz
)
set(OPTIMIZE_FLAGS
    -Oz
)
# -----------------------------------------------------------------------------
#  Common warnings 
# -----------------------------------------------------------------------------
set(COMMON_FLAGS
    -Wall
    -ffunction-sections
    -fdata-sections
)

# Apply the flags to every compile command
add_compile_options(${MCU_FLAGS} ${COMMON_FLAGS} ${OPTIMIZE_FLAGS})

# Build‑type‑specific optimiser/debug switches
set(CMAKE_C_FLAGS_DEBUG   -g3 -O0 -DDEBUG)
set(CMAKE_C_FLAGS_RELEASE -O3 -DNDEBUG)

# -----------------------------------------------------------------------------
#  Pre‑processor symbols (HAL, CMSIS, CMSIS‑DSP)
# -----------------------------------------------------------------------------
add_compile_definitions(
    STM32F411xE
    USE_HAL_DRIVER
    ARM_MATH_CM4
    ARM_MATH_MATRIX_CHECK
    ARM_MATH_ROUNDING
    __FPU_PRESENT=1
)

# -----------------------------------------------------------------------------
#  Include directories (o
# -----------------------------------------------------------------------------
## MANUAL INCLUDING HEADER DIR
# include_directories(
#     ${PROJECT_SOURCE_DIR}/Core/Inc
#     ${PROJECT_SOURCE_DIR}/Drivers/CMSIS/Device/ST/STM32F4xx/Include
#     ${PROJECT_SOURCE_DIR}/Drivers/CMSIS/Include
#     ${PROJECT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Inc
#     ${PROJECT_SOURCE_DIR}/Drivers/STM32F4xx_HAL_Driver/Inc/Legacy
#     ${PROJECT_SOURCE_DIR}/USB_DEVICE/App
#     ${PROJECT_SOURCE_DIR}/USB_DEVICE/Target
#     ${PROJECT_SOURCE_DIR}/Middlewares/ST/STM32_USB_Device_Library/Core/Inc
#     ${PROJECT_SOURCE_DIR}/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc
# )

## AUTOMATION INCLUDING HEADER DIR

file(GLOB_RECURSE HEADERS CONFIGURE_DEPENDS 
    ${PROJECT_SOURCE_DIR}/*.h
)

set(INCLUDE_DIRS )
foreach(header ${HEADERS})
    get_filename_component(header_dir ${header} DIRECTORY )
    list(APPEND INCLUDE_DIRS ${header_dir})
endforeach()

list(REMOVE_DUPLICATES INCLUDE_DIRS)

include_directories(
    ${INCLUDE_DIRS}
)
# -----------------------------------------------------------------------------
#  Source files (C) 
# -----------------------------------------------------------------------------
# file(GLOB_RECURSE SOURCES
#     Core/Src/*.c
#     Drivers/STM32F4xx_HAL_Driver/Src/*.c
#     Middlewares/ST/STM32_USB_Device_Library/Core/Src/*.c
#     Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Src/*.c
#     USB_DEVICE/App/*.c
#     USB_DEVICE/Target/*.c)

file(GLOB_RECURSE ALL_C_FILES CONFIGURE_DEPENDS
    ${PROJECT_SOURCE_DIR}/*.c
)

# Filter out CMake temporary files
set(SOURCES)
foreach(c_file ${ALL_C_FILES})
    # Skip CMake compiler test files
    if(NOT c_file MATCHES "CMakeCCompilerId\\.c$" AND 
       NOT c_file MATCHES "CMakeFiles/" AND
       NOT c_file MATCHES "build/")
        list(APPEND SOURCES ${c_file})
    endif()
endforeach()
# -----------------------------------------------------------------------------
#  Startup assembly file (search both .s and .S in Core/Startup)
# -----------------------------------------------------------------------------
# file(GLOB STARTUP_FILE
#      Core/Startup/*.s
#      Core/Startup/*.S
# )
file(GLOB_RECURSE STARTUP_FILE
    ${PROJECT_SOURCE_DIR}/*.s
    ${PROJECT_SOURCE_DIR}/*.S
)

if(STARTUP_FILE)
    list(APPEND SOURCES ${STARTUP_FILE})
else()
    message(WARNING "Startup file not found in Core/Startup – check file name (e.g. startup_stm32f411vetx.s)")
endif()

# -----------------------------------------------------------------------------
#  Linker script — adjust name if you rename the .ld file
# -----------------------------------------------------------------------------
set(LINKER_SCRIPT ${PROJECT_SOURCE_DIR}/STM32F411VETX_FLASH.ld)
if(NOT EXISTS ${LINKER_SCRIPT})
    message(FATAL_ERROR "Linker script not found: ${LINKER_SCRIPT}")
endif()

# -----------------------------------------------------------------------------
#  Create ELF target
# -----------------------------------------------------------------------------
add_executable(${PROJECT_NAME}.elf ${SOURCES})

# -----------------------------------------------------------------------------
#  Linker options — order matters: place script first
# -----------------------------------------------------------------------------

target_link_options(${PROJECT_NAME}.elf PRIVATE
    -T${LINKER_SCRIPT}
    -Wl,-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map
    -Wl,--gc-sections
    -static
    --specs=nano.specs
    --specs=nosys.specs
    ${MCU_FLAGS}
    ${OPTIMIZE_FLAGS}
)

# -----------------------------------------------------------------------------
#  Post‑build: BIN, HEX & size report
# -----------------------------------------------------------------------------
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${PROJECT_NAME}.elf> ${PROJECT_NAME}.bin
    COMMAND ${CMAKE_OBJCOPY} -O ihex   $<TARGET_FILE:${PROJECT_NAME}.elf> ${PROJECT_NAME}.hex
    COMMAND ${CMAKE_SIZE}              $<TARGET_FILE:${PROJECT_NAME}.elf>
    COMMENT "[post-build]  Generated BIN & HEX, printed size"
)

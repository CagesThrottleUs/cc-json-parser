cmake_minimum_required(VERSION 3.20)

project(ccjsonparser
    VERSION 0.1.0
    DESCRIPTION "High-performance JSON parser for HFT"
    LANGUAGES CXX
)

# ===============================
# Compiler and Language Standards
# ===============================
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Always export compile_commands.json (for clangd / tooling / clang-tidy)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ===============================
# Options
# ===============================
option(HFT_NO_EXCEPTIONS "Disable exceptions for latency-critical builds" OFF)
option(HFT_NO_RTTI "Disable RTTI (runtime type information)" ON)

# =============
# Sources
# =============
set(SOURCES
    src/main.cpp
)

set(HEADERS
    # add public headers here if needed
)

add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# =================
# Compiler Warnings
# =================
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang|AppleClang|GNU")
    target_compile_options(${PROJECT_NAME} PRIVATE
        -Wall -Wextra -Wpedantic
        -Wshadow -Wconversion -Wsign-conversion
        -Wold-style-cast -Woverloaded-virtual -Wnon-virtual-dtor
        -Wnull-dereference -Wdouble-promotion -Wformat=2
        -Werror # HFT: warnings are bugs
    )

    if (HFT_NO_EXCEPTIONS)
        target_compile_options(${PROJECT_NAME} PRIVATE -fno-exceptions)
        message(STATUS "HFT: exceptions disabled (-fno-exceptions)")
    else()
        message(STATUS "HFT: exceptions enabled (parser-friendly)")
    endif()

    if (HFT_NO_RTTI)
        target_compile_options(${PROJECT_NAME} PRIVATE -fno-rtti)
        message(STATUS "HFT: RTTI disabled (-fno-rtti)")
    endif()

    target_compile_options(${PROJECT_NAME} PRIVATE -ffast-math) # HFT: faster math
elseif (MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /W4 /permissive-)
    if (HFT_NO_EXCEPTIONS)
        target_compile_options(${PROJECT_NAME} PRIVATE /EHs-c-)
    endif()
    if (HFT_NO_RTTI)
        target_compile_options(${PROJECT_NAME} PRIVATE /GR-)
    endif()
endif()

# ======================
# Optimization Levels
# ======================
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG -march=native -flto -fstrict-aliasing")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g3 -fno-omit-frame-pointer -fsanitize=address,undefined")

# ============
# Dependencies
# ============
# (Hook in benchmarking or testing frameworks here later)
# find_package(Boost REQUIRED COMPONENTS iostreams locale CONFIG)
# target_link_libraries(${PROJECT_NAME} PRIVATE Boost::iostreams Boost::locale)

# ============
# Installation
# ============
install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)

# Install auxiliary directories into bin
foreach(dir challenges hardcore testsuite)
    if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dir}")
        install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${dir}/"
                DESTINATION bin/${dir}
                FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
                DIRECTORY_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
        )
    else()
        message(WARNING "${dir} directory not found — skipping its installation")
    endif()
endforeach()

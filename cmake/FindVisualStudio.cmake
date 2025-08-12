# FindVisualStudio.cmake
# Shared module to detect Visual Studio installation path
# Sets VS_PATH variable with the Visual Studio installation directory

function(find_visual_studio_path)
    # Return early if VS_PATH is already set and valid
    if(VS_PATH AND EXISTS "${VS_PATH}/VC/Tools/Llvm/x64/bin/clang-cl.exe")
        return()
    endif()

    # Try using vswhere.exe first (modern VS installer)
    execute_process(
        COMMAND cmd /c "for /f \"usebackq tokens=*\" %i in (`\"%ProgramFiles(x86)%\\Microsoft Visual Studio\\Installer\\vswhere.exe\" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do @echo %i"
        OUTPUT_VARIABLE VS_PATH_VSWHERE
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE VS_RESULT
        ERROR_QUIET
    )

    if(VS_RESULT EQUAL 0 AND VS_PATH_VSWHERE AND EXISTS "${VS_PATH_VSWHERE}/VC/Tools/Llvm/x64/bin/clang-cl.exe")
        set(VS_PATH "${VS_PATH_VSWHERE}" PARENT_SCOPE)
        message(STATUS "Found Visual Studio via vswhere: ${VS_PATH_VSWHERE}")
        return()
    endif()

    # Fallback: try common installation paths
    set(PROGRAM_FILES_X86 "ProgramFiles(x86)")
    set(VS_TEST_PATHS
        "$ENV{ProgramFiles}/Microsoft Visual Studio/2022/Enterprise"
        "$ENV{ProgramFiles}/Microsoft Visual Studio/2022/Professional" 
        "$ENV{ProgramFiles}/Microsoft Visual Studio/2022/Community"
        "$ENV{${PROGRAM_FILES_X86}}/Microsoft Visual Studio/2022/Enterprise"
        "$ENV{${PROGRAM_FILES_X86}}/Microsoft Visual Studio/2022/Professional"
        "$ENV{${PROGRAM_FILES_X86}}/Microsoft Visual Studio/2022/Community"
    )

    foreach(VS_TEST_PATH ${VS_TEST_PATHS})
        if(EXISTS "${VS_TEST_PATH}/VC/Tools/Llvm/x64/bin/clang-cl.exe")
            set(VS_PATH "${VS_TEST_PATH}" PARENT_SCOPE)
            message(STATUS "Found Visual Studio via fallback path: ${VS_TEST_PATH}")
            return()
        endif()
    endforeach()

    # If we get here, VS was not found
    message(FATAL_ERROR "Could not find Visual Studio installation with LLVM tools. Please ensure Visual Studio 2022 with C++ Clang tools are installed.")
endfunction()

# Main function that sets up VS_PATH and related variables
function(setup_visual_studio_environment)
    find_visual_studio_path()
    
    if(NOT VS_PATH OR NOT EXISTS "${VS_PATH}/VC/Tools/Llvm/x64/bin/clang-cl.exe")
        message(FATAL_ERROR "Could not find valid Visual Studio installation")
    endif()

    # Cache the VS_PATH for use in custom commands and other contexts
    set(VS_PATH_CACHE "${VS_PATH}" CACHE INTERNAL "Visual Studio Path")
    
    # Find MSVC version
    file(GLOB MSVC_VERSION_DIRS "${VS_PATH}/VC/Tools/MSVC/*")
    foreach(MSVC_VERSION_DIR ${MSVC_VERSION_DIRS})
        get_filename_component(MSVC_VERSION_CANDIDATE "${MSVC_VERSION_DIR}" NAME)
        if(EXISTS "${MSVC_VERSION_DIR}/bin/HostX64/ARM64/link.exe")
            set(MSVC_VERSION "${MSVC_VERSION_CANDIDATE}")
        endif()
    endforeach()
    
    if(NOT MSVC_VERSION)
        message(FATAL_ERROR "Could not find MSVC version with ARM64 tools in ${VS_PATH}")
    endif()
    
    # Cache MSVC version as well
    set(MSVC_VERSION_CACHE "${MSVC_VERSION}" CACHE INTERNAL "MSVC Version")
    
    # Export variables to parent scope
    set(VS_PATH "${VS_PATH}" PARENT_SCOPE)
    set(MSVC_VERSION "${MSVC_VERSION}" PARENT_SCOPE)
    
    message(STATUS "Visual Studio Path: ${VS_PATH}")
    message(STATUS "MSVC Version: ${MSVC_VERSION}")
endfunction()

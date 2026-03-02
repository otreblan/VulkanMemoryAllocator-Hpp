
# VMA_HPP_VMA_REVISION can be overridden from the command line, but does not persist in cache
if (NOT DEFINED VMA_HPP_VMA_REVISION)
    set(VMA_HPP_VMA_REVISION "v${PROJECT_VERSION}")
endif ()

find_package(Git)
if (NOT Git_FOUND)
    message(FATAL_ERROR "Git not found. VMA_HPP_DO_UPDATE is not available.")
endif ()

execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" COMMAND_ERROR_IS_FATAL ANY)

message(STATUS "Updating VulkanMemoryAllocator submodule to ${VMA_HPP_VMA_REVISION}")
execute_process(COMMAND ${GIT_EXECUTABLE} fetch origin tag "${VMA_HPP_VMA_REVISION}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/VulkanMemoryAllocator" COMMAND_ERROR_IS_FATAL ANY)
execute_process(COMMAND ${GIT_EXECUTABLE} -c advice.detachedHead=false checkout "${VMA_HPP_VMA_REVISION}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/VulkanMemoryAllocator" COMMAND_ERROR_IS_FATAL ANY)
execute_process(COMMAND ${GIT_EXECUTABLE} pull
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/VulkanMemoryAllocator" ERROR_QUIET)


function(pad_configuration_table_entry RESULT INPUT LENGTH)
    string(LENGTH "${INPUT}" L)
    math(EXPR L "${LENGTH} - ${L}")
    string(REPEAT "~" ${L} R)
    set(${RESULT} "${R}" PARENT_SCOPE)
endfunction()

function(generate_configuration_table)
    # Find testing configurations in the GH workflow.
    file(READ "${CMAKE_CURRENT_SOURCE_DIR}/.github/workflows/build-custom-vulkan.yml" WORKFLOW_SOURCE)
    set(REGEX "build +\\$\{{ *env\.vk *\\|\\| *env\.modules *&& *'v([^']+)' *\\|\\| *'v([^']+)'}} *([^\n$]*)")
    string(REGEX MATCHALL "${REGEX}" CONFIGS ${WORKFLOW_SOURCE})
    # Prepare padded line segments.
    set(CONFIG_LINES " `~~~~Min Vulkan~~~~` `~Tested configurations;`#include` `~~import` `~Flags")
    set(LONGEST_LINE 0)
    foreach(CONFIG ${CONFIGS})
        string(REGEX MATCH "${REGEX}" _ ${CONFIG})
        pad_configuration_table_entry(PAD_1 "${CMAKE_MATCH_1}" 8)
        pad_configuration_table_entry(PAD_2 "${CMAKE_MATCH_2}" 8)
        string(LENGTH "${CMAKE_MATCH_3}" L)
        if(L GREATER LONGEST_LINE)
            set(LONGEST_LINE ${L})
        elseif (L EQUAL 0)
            set(MIN_VULKAN "${CMAKE_MATCH_2}" PARENT_SCOPE) # Remember Vulkan version for default configuration.
        endif()
        list(APPEND CONFIG_LINES "`${PAD_2}${CMAKE_MATCH_2}` `${PAD_1}${CMAKE_MATCH_1}` `${CMAKE_MATCH_3}")
    endforeach()
    # Build a table of configurations.
    set(CONFIG_TABLE "\n\n ")
    foreach(CONFIG_LINE ${CONFIG_LINES})
        pad_configuration_table_entry(PAD "${CONFIG_LINE}" "24 + ${LONGEST_LINE}")
        string(APPEND CONFIG_TABLE "  ${CONFIG_LINE}${PAD}`<br>\n  ")
    endforeach()
    # Replace placeholders with padding sequences.
    string(REPLACE "~" "​ ​" CONFIG_TABLE "${CONFIG_TABLE}")
    string(REPLACE "​​" "​" CONFIG_TABLE "${CONFIG_TABLE}")
    set(CONFIG_TABLE "${CONFIG_TABLE}" PARENT_SCOPE)
endfunction()
generate_configuration_table()

# Find VMA version in the VMA header.
file(READ "${VMA_HPP_INPUT_HEADER}" VMA_SOURCE)
string(REGEX MATCH "<b>Version\\s*([^<]+)\\s*</b>" _ ${VMA_SOURCE})
string(STRIP ${CMAKE_MATCH_1} VMA_VERSION)

# Update versions in the README.
function(replace_readme PLACEHOLDER CONTENT)
    string(REGEX REPLACE "<!--${PLACEHOLDER}-->([^<]*<[^!])*[^<]*<!--/${PLACEHOLDER}-->" "<!--${PLACEHOLDER}-->${CONTENT}<!--/${PLACEHOLDER}-->" README_SOURCE "${README_SOURCE}")
    set(README_SOURCE "${README_SOURCE}" PARENT_SCOPE)
endfunction()
message(STATUS "Updating README with VMA ${VMA_VERSION} and Vulkan ${MIN_VULKAN}")
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/README.md" README_SOURCE)
string(REPLACE ";" "\\;" README_SOURCE "${README_SOURCE}") # Do not mess up semicolons in the README
replace_readme(VER "${VMA_VERSION}")
replace_readme(MIN_VK "${MIN_VULKAN}")
replace_readme(MIN_VK_TABLE "${CONFIG_TABLE}")
file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/README.md" ${README_SOURCE})

# Generate "imported" utility header.
set(IMPORTED_HEADER "// Generated from the list of VMA-Hpp headers (vk_mem_alloc*.hpp).
// See https://clang.llvm.org/docs/StandardCPlusPlusModules.html#providing-a-header-to-skip-parsing-redundant-headers")
file(GLOB HEADER_FILES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/include" "${CMAKE_CURRENT_SOURCE_DIR}/include/vk_mem_alloc*.hpp")
foreach(HEADER_FILE ${HEADER_FILES})
    if (NOT ${HEADER_FILE} STREQUAL "vk_mem_alloc_imported.hpp" AND
            NOT ${HEADER_FILE} STREQUAL "vk_mem_alloc_static_assertions.hpp")
        string(REGEX MATCH "vk_mem_alloc(.*)\.hpp" _ ${HEADER_FILE})
        string(TOUPPER "${CMAKE_MATCH_1}" HEADER_GUARD)
        string(APPEND IMPORTED_HEADER "

#ifndef VULKAN_MEMORY_ALLOCATOR${HEADER_GUARD}_HPP
#define VULKAN_MEMORY_ALLOCATOR${HEADER_GUARD}_HPP
#endif")
    endif ()
endforeach()
file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/include/vk_mem_alloc_imported.hpp" ${IMPORTED_HEADER})
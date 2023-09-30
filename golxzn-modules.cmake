
function(golxzn_unpack_module)
	cmake_parse_arguments(GXZN "" "NAME;PATH" "" ${ARGN})
	if(NOT GXZN_NAME)
		message(WARNING "[golxzn] Missing 'NAME' option")
	endif()

	if(NOT GXZN_PATH)
		set(GXZN_PATH ${CMAKE_SOURCE_DIR}/modules)
	endif()

	set(unpacked_archive_dir ${CMAKE_BINARY_DIR}/golxzn_modules)
	if (EXISTS ${unpacked_archive_dir}/${GXZN_NAME})
		return()
	endif()

	if(EXISTS ${GXZN_PATH}/${GXZN_NAME} AND GXZN_NAME MATCHES "zip")
		file(ARCHIVE_EXTRACT
			INPUT ${GXZN_PATH}/${GXZN_NAME}
			DESTINATION ${unpacked_archive_dir}
		)
	endif()
endfunction()


function(golxzn_get_module_priority priority)
	cmake_parse_arguments(GXZN "" "NAME;PATH" "" ${ARGN})
	if(NOT GXZN_NAME)
		message(WARNING "[golxzn] Missing 'NAME' option")
	endif()

	if(NOT GXZN_PATH)
		set(GXZN_PATH ${CMAKE_SOURCE_DIR}/modules)
	endif()

	if(GXZN_NAME MATCHES "zip")
		golxzn_unpack_module(NAME ${GXZN_NAME} PATH ${GXZN_PATH})
		set(GXZN_PATH ${CMAKE_BINARY_DIR}/golxzn_modules)
		get_filename_component(GXZN_NAME ${GXZN_NAME} NAME_WLE)
	endif()

	set(full_path ${GXZN_PATH}/${GXZN_NAME})
	file(GLOB priority_file RELATIVE ${full_path} CONFIGURE_DEPENDS ${full_path}/priority.*)
	unset(full_path)

	if(priority_file)
		get_filename_component(_priority ${priority_file} LAST_EXT)
		string(SUBSTRING ${_priority} 1 -1 _priority)
	else()
		set(_priority -1)
	endif()

	set(${priority} ${_priority} PARENT_SCOPE)
	unset(_priority)
endfunction()

function(golxzn_add_module)
	cmake_parse_arguments(GXZN "" "NAME;PATH" "" ${ARGN})
	if(NOT GXZN_NAME)
		message(WARNING "[golxzn] Missing 'NAME' option")
	endif()

	if(NOT GXZN_PATH)
		set(GXZN_PATH ${CMAKE_SOURCE_DIR}/modules)
	endif()

	if(GXZN_NAME MATCHES "zip")
		golxzn_unpack_module(NAME ${GXZN_NAME} PATH ${GXZN_PATH})
		set(GXZN_PATH ${CMAKE_BINARY_DIR}/golxzn_modules)
		get_filename_component(GXZN_NAME ${GXZN_NAME} NAME_WLE)
	endif()

	if(NOT EXISTS ${GXZN_PATH}/${GXZN_NAME}/gmodule.cmake)
		return()
	endif()

	if (TARGET golxzn::${GXZN_NAME})
		message(VERBOSE "[golxzn] Module '${GXZN_NAME}' is already added")
		return()
	endif()

	include(${GXZN_PATH}/${GXZN_NAME}/gmodule.cmake)
endfunction()

# Load all modules from the specified directory.
# The modules are loaded in the order of their priorities.
# The priority of each module is determined by the file "priority.<number>".
# Arguments:
#   PATH             - directory containing the modules
#   DISABLED_MODULES - list of modules to be ignored
function(golxzn_load_modules)
	cmake_parse_arguments(GXZN "" "PATH" "DISABLED_MODULES" ${ARGN})
	if(NOT GXZN_PATH)
		set(GXZN_PATH ${CMAKE_SOURCE_DIR}/modules)
	endif()
	message(STATUS "[golxzn] Loading modules from: '${GXZN_PATH}'")
	if(GXZN_DISABLED_MODULES)
		message(VERBOSE "[golxzn]     Disabled modules: ${GXZN_DISABLED_MODULES}")
	endif()

	get_filename_component(GXZN_PATH "${GXZN_PATH}" ABSOLUTE)

	file(GLOB modules LIST_DIRECTORIES true RELATIVE ${GXZN_PATH} CONFIGURE_DEPENDS ${GXZN_PATH}/*)
	message(STATUS "[golxzn] Found modules:")
	set(prioritized_modules)
	foreach(module IN LISTS modules)
		if(NOT IS_DIRECTORY ${GXZN_PATH}/${module} OR EXISTS ${GXZN_PATH}/${module}/.gignore)
			continue()
		endif()

		golxzn_get_module_priority(${module}_priority NAME ${module} PATH ${GXZN_PATH})

		message(STATUS "[golxzn]    > golxzn::${module} (${${module}_priority})")
		list(APPEND prioritized_modules ${${module}_priority}.${module})
	endforeach()

	list(SORT prioritized_modules)

	add_library(golxzn_modules INTERFACE)
	add_library(golxzn::modules ALIAS golxzn_modules)

	foreach(module IN LISTS prioritized_modules)
		string(FIND ${module} "." priority_index)
		math(EXPR priority_index "${priority_index}+1")
		string(SUBSTRING ${module} ${priority_index} -1 module)

		golxzn_add_module(NAME ${module} PATH ${GXZN_PATH})
		target_link_libraries(golxzn_modules INTERFACE golxzn::${module})
		target_compile_definitions(golxzn_modules INTERFACE
			$<TARGET_PROPERTY:golxzn::${module},INTERFACE_COMPILE_DEFINITIONS>
		)
	endforeach()
endfunction()

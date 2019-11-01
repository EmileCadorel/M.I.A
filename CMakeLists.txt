CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT(MIA)
SET(CMAKE_C_COMPILER "gyc")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -fPIC -g")

FILE (
  GLOB_RECURSE
  SRC_CORE
  core/*.yr
  )

FILE (
  GLOB_RECURSE
  SRC_STD
  std/*.yr
  )

FILE (
  GLOB_RECURSE
  SRC_CORE_C
  core/*.c
  )

FILE (
  GLOB_RECURSE
  SRC_STD_C
  std/*.c
  )


FILE (
  GLOB_RECURSE
  SRC
  source/*.yr
  )

set( CMAKE_VERBOSE_MAKEFILE on )

SET_SOURCE_FILES_PROPERTIES(${SRC_CORE} ${SRC_STD} ${SRC_CORE_C} ${SRC_STD_C} ${SRC} PROPERTIES LANGUAGE C)
add_executable(MIA ${SRC_CORE} ${SRC_STD} ${SRC_CORE_C} ${SRC_STD_C} ${SRC})
target_link_libraries (MIA -lpthread -lgc -lgyruntime -lgmp)
include_directories(${CMAKE_SOURCE_DIR}/)

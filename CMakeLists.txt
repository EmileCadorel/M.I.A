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
  SRC
  source/*.yr
  )

SET_SOURCE_FILES_PROPERTIES(${SRC_CORE} ${SRC_STD} ${SRC} PROPERTIES LANGUAGE C)
add_executable(MIA ${SRC_CORE} ${SRC_STD} ${SRC})
target_link_libraries (MIA -lpthread -lgc -lgyruntime -lgmp)
include_directories(${CMAKE_SOURCE_DIR})

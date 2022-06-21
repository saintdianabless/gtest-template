cmake_minimum_required(VERSION 3.15)

project(gtest-template C CXX)

set(CXX_STANDARD 11)
set(CXX_STANDARD_REQUIRED ON)

include(cmake/utils.cmake)

find_package(GTest CONFIG REQUIRED)

set(libs GTest::gtest GTest::gtest_main)

cxx_test(simple "${libs}")


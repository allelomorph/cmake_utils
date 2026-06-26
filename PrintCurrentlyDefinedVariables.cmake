cmake_minimum_required(VERSION 3.15)

# adapted from https://stackoverflow.com/questions/9298278/
macro(print_currently_defined_variables)
  get_cmake_property(_variable_names VARIABLES)
  list (SORT _variable_names)
  foreach (_variable_name ${_variable_names})
    message("${_variable_name}=${${_variable_name}}")
  endforeach()
endmacro()

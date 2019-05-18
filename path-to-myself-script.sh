#!/bin/bash
#
#   relative path to script, from current working directory
#
echo "${BASH_SOURCE[@]}"




#   the name of the script in environment variables:
#   	main function is the first item in array of all functions
#       and parallel array of relative filepaths from current working dir
#
echo "FUNCNAME:    ${FUNCNAME[@]}"
echo "BASH_SOURCE: ${BASH_SOURCE[@]}"


#   the containing dir name of the script
#   
dirname "${BASH_SOURCE[0]}"

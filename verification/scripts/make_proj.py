#!/usr/bin/env python

import os
import sys
import argparse
import subprocess
import utility as util
#=======================================================================
# Globals
#=======================================================================
default_path_for_proj = ""
default_path_to_fpga_dir = "../"
#=======================================================================
# Utility Funcs
#=======================================================================
def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--project_name', help='Project Name', required=True)
    parser.add_argument('-p', '--path_proj', help='Path for project')
    parser.add_argument('-f', '--path_fpga', help='Path for fpga (contains scripts and utilities)')
    parser.add_argument('-d', '--dependancy', help='path to dependency file defining which IPs this project is going to re-use')
    parser.add_argument('-v', '--vebosity', help='vebosity for priting log messages', default='VERB_HIGH')

    args = parser.parse_args()
    return vars(args)

def read_dep_file(file):
    deps_path = []
    util.check_for_file(file)
    with open(file) as f:
        lines = f.readlines() 
        for dep in lines:
            dep.replace("\n", "").replace(" ", "")
            deps_path.append(dep)
    return deps_path

def link_dependencies(proj_base_path, dep_path, verbosity="VERB_HIGH"):
    # import ipdb as pdb; pdb.set_trace()
    proj_rtl_dir = proj_base_path + "/rtl/"
    command = "cd " + proj_rtl_dir
    util.run_command(command, verbosity=verbosity)
    for ip_path in dep_path:
        ip_path = ip_path.replace("\n", "")
        util.check_for_file(ip_path, exit=False)
        command = "ln -s " + ip_path + " " + proj_rtl_dir
        util.run_command(command, verbosity=verbosity)

def create_f_file(proj_base_path, deps, verbosity="VERB_HIGH"):
    # import ipdb as pdb; pdb.set_trace()
    path_to_ffile = "{0}/scripts/files.f".format(proj_dir)
    command = "touch {0}".format(path_to_ffile)
    util.run_command(command, verbosity=verbosity)
    ips = []
    with open(path_to_ffile, "w") as f:
        for dep in deps:
            ip = dep.split("/")[-1].split("\n")[0]
            f.write("../rtl/"+ip+"\n")
        f.close()


#=======================================================================
# Main
#=======================================================================
if __name__ == '__main__':
    cmd_to_run = ""
    __args__ = parse_args()
    project_name  = __args__['project_name']
    path_for_proj = __args__['path_proj']
    path_fpga     = __args__['path_fpga']
    verbosity     = __args__['vebosity']
    util.print_banner("Creating {0} Project".format(project_name), verbosity="VERB_LOW")
    # import ipdb as pdb; pdb.set_trace()
    if path_for_proj == None:
        default_path_for_proj = os.getcwd() + "/"
        util.print_log("Using current path for creating project: {0}".format(default_path_for_proj))
        path_for_proj = default_path_for_proj
    if path_fpga == None:
        util.print_log("Using default path to fpga directory {0}".format(default_path_to_fpga_dir))
        path_fpga = default_path_to_fpga_dir
# Check if project has already been created
    if os.path.isdir("{0}{1}".format(path_for_proj, project_name)):
        util.print_log("Project path {0}{1} already exist!".format(path_for_proj, project_name), id_str="ERROR")
        sys.exit()
    if os.getcwd() not in path_for_proj:
        proj_dir = os.getcwd() + "/" + path_for_proj + project_name
    else:
        proj_dir = path_for_proj + project_name
    proj_dir = os.path.abspath(proj_dir)
    # import ipdb as pdb; pdb.set_trace()
    command = "mkdir {0}".format(project_name)
    util.run_command(command, verbosity=verbosity)
    command = "cd {0}".format(proj_dir)
    util.run_command(command, verbosity=verbosity)
    command = "mkdir {0}/docs {0}/results {0}/rtl {0}/scripts {0}/sw {0}/tb".format(proj_dir)
    util.run_command(command, verbosity=verbosity)
    command = "touch {0}/rtl/{1}.sv".format(proj_dir, project_name.lower())
    util.run_command(command, verbosity=verbosity)
    command = "touch {0}/tb/{1}_tester.sv".format(proj_dir, project_name.lower())
    util.run_command(command, verbosity=verbosity)
    if not (__args__['dependancy']) == None :
        deps = read_dep_file(__args__['dependancy'])
        link_dependencies(proj_dir, deps, verbosity=verbosity )
        create_f_file(proj_dir, deps, verbosity=verbosity )

    util.print_log("Done!")
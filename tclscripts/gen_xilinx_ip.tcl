#!/usr/bin/tclsh

# Source other scripts
source common.tcl

# Set some directories
set xcisrcpath ../ip/xilinx
set buildpath ../ip/build/xilinx
set verifyippath ../verification/ip/xilinx
file mkdir $buildpath

# IP's to generate
set ipnames {
    bram64k_64x1024_xilinx
    bram2m_xilinx
}


# Copies an IP file in .xci format from the source IP directory to it's own build directory
proc cpIPFiletoBuild {ipname} {
    global buildpath
    global xcisrcpath
    set ipbuilddir $buildpath/$ipname/
    file mkdir $ipbuilddir
    file copy -force $xcisrcpath/$ipname.xci $ipbuilddir
}

# Generates the IP files
proc genIPFiles {ipname} {
    global buildpath
    set ipbuilddir $buildpath/$ipname/
    set ipXCIfile $ipname.xci
    read_ip $ipbuilddir/$ipXCIfile
    set locked [get_property IS_LOCKED [get_ips $ipname]]
    set upgrade [get_property UPGRADE_VERSIONS [get_ips $ipname]]
    if {$locked && $upgrade != ""} {
    	upgrade_ip [get_ips $ipname]
    }
    generate_target -force all [get_ips $ipname]
    #catch { config_ip_cache -export [get_ips -all $ipname] }
    #export_ip_user_files -of_objects [get_files $ipXCIfile -no_script -sync -force -quiet]
    #create_ip_run [get_files -of_objects [get_fileset sources_1] $ipbuilddir/$ipXCIfile]
}

proc cpIPSimFileToVerification {ipname} {
    global buildpath
    global verifyippath
    file mkdir $verifyippath
    set ipsimbuildfile $buildpath/$ipname/sim/$ipname.v
    file copy -force $ipsimbuildfile $verifyippath
}


# Generate IPs
foreach ipname $ipnames {
    puts "\n** Generating $ipname **\n"
    cpIPFiletoBuild $ipname
    genIPFiles $ipname
    cpIPSimFileToVerification $ipname
}

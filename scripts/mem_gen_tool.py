MB = (1024*1024)
KB = (1024)

def format_size(sz):
    fmt = 'MB' if (sz/MB)>0 else 'KB'
    sz = sz/MB if fmt=='MB' else sz/KB
    return "{:2.2f} {}".format(sz, fmt)

def phex(data):
    data = '0x{0:0{1}X}'.format(data,8)
    return "0x{}_{}".format(data[2:6], data[6:10])

ram_sz = {"MVU_W": 15*MB, "MVU_D":15*MB, "MVU_S":1*MB, "MVU_B":1*MB}
ram_used = {"MVU_W": 1*MB, "MVU_D":1*MB, "MVU_S":8*KB, "MVU_B":16*KB}
MVU_MEM_START_ADDR = 0x7000_0000

cur_addr = MVU_MEM_START_ADDR
for mvu in range(0,8):
    mvu_addr_start = cur_addr
    mvu_addr_end   = cur_addr+32*MB
    print("MVU[{:1d}]: {:10s}-{:10s}".format(mvu, phex(mvu_addr_start), phex(mvu_addr_end)))
    for ram_region, sz in ram_sz.items():
        # import ipdb as pdb; pdb.set_trace()
        start_mem = cur_addr
        end_mem = start_mem + sz
        rsvd_start = start_mem+ram_used[ram_region]
        rsvd_sz = (end_mem-rsvd_start)
        print("\t{:5s}[{:10s}]:{:10s}-{:10s}   RSVD[{:10s}]: {:10s}-{:10s}".format(ram_region, format_size(ram_used[ram_region]), phex(cur_addr), phex(rsvd_start), format_size(rsvd_sz), phex(rsvd_start), phex(end_mem)))
        cur_addr += sz

import argparse
import hjson
import math
    
def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input_reg_desc', help='input register file description', required=True)
    parser.add_argument('-f', '--format', help='Output format', choices=["c-header", "sv"], default="sv")
    args = parser.parse_args()
    return vars(args)

def process_reg_file(file, args): 
    with open(file) as json_file:
        data = hjson.load(json_file)
        baseaddr = int(data['baseaddr'], 16)
        regwidth = int(data['regwidth'])
        addr = baseaddr
        reg_addr_length = math.ceil(math.log2(addr))
        if args['format']=="sv":
            out_str = "typedef enum logic [{}:0] {{\n".format(reg_addr_length-1)
        elif args['format']=="c-header":
            out_str = ""
        else:
            print("Unknown output format {}".format(['format']))
        for regs in data['registers']:
            if args['format']=="sv":
                # import ipdb as pdb; pdb.set_trace()
                out_str += "\t{}={}'h{:x},//{}\n".format(regs['name'], reg_addr_length, addr, regs['desc'])
            elif args['format']=="c-header":
                out_str += "#define {} 0x{:x}//{}\n".format(regs['name'], addr, regs['desc'])
            addr += 1
        if args['format']=="sv":
            out_str += "} mvu_csr_t;"
        elif args['format']=="c-header":
            out_str += ""
        print(out_str)

if __name__ == '__main__':
    args = parse_args()
    i_ref_file = args['input_reg_desc']
    process_reg_file(i_ref_file, args)
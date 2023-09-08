import { BigNumber } from "ethers";
export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
export const MAX_UINT64 = BigNumber.from('0xffffffffffffffff'); // 18446744073709551615
export const DEPLOY_CACHE = 'deployedContracts.json';
export const CONTENT = "CONTENT";

export const ACTIONS = {
    PARENT: {
        REVOKE: "0x20c5429b"
    },
    CHILD: {
        UPDATE: "0x82ab890a",
        TRANSFER: "0x23b872dd"
    }
}
import {
    Validator,
    Distributor,
    MockFT,
    MockNFT
} from "../typechain-types";

export interface IContracts {
    distributor: Distributor
    validator: Validator,
    test: {
        mockFT: MockFT,
        mockNFT: MockNFT
    }
}

export interface IContractAddresses {
    distributor: string,
    validator: string,
    test: {
        mockFT: string,
        mockNFT: string
    }
}
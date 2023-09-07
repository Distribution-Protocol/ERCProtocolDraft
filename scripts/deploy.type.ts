import {
    Validator,
    Distributor,
    MockFT,
    MockNFT
} from "../typechain-types";

export interface IContracts {
    distributor: Distributor
    validator: Validator,
    mock: {
        ERC20: MockFT,
        ERC721: MockNFT
    }
}

export interface IContractAddresses {
    distributor: string,
    validator: string,
    mock: {
        ERC20: string,
        ERC721: string
    }
}
import { BytesLike, ethers } from 'ethers';
import { BigNumberish } from 'ethers';

// export type MintTuple = [string, BigNumberish, string, boolean, boolean, boolean, boolean];
export type CopyValidationTuple = [string, BigNumberish, BigNumberish, string, BigNumberish, BigNumberish, BigNumberish];

export interface NftDescriptor {
  contractAddress: string,
  tokenId: BigNumberish,
}

export interface MintData {
    validator: string,
    descriptor: NftDescriptor,
    creatorActions: BytesLike[],
    collectorActions: BytesLike[]
}

export interface CopyValidationData {
    feeToken: string;
    duration: BigNumberish;
    mintAmount: BigNumberish;
    requiredERC721Token: string;
    limit: BigNumberish;
    start: BigNumberish;
    time: BigNumberish;
}

export const getEncodedValidationData = (validationInfo: CopyValidationTuple) => {
return ethers.utils.defaultAbiCoder.encode(
    ['tuple(address, uint64, uint256, address, uint256, uint64, uint64)'],
    [validationInfo]
    );
};

export const getCopyValidationData = (data: CopyValidationData): CopyValidationTuple => {
    return [
      data.feeToken,
      data.duration,
      data.mintAmount,
      data.requiredERC721Token,
      data.limit,
      data.start,
      data.time
    ];
};

export const getNow = (): number => {
  return Math.floor(new Date().getTime() / 1000);
}

export const getDeadline = (seconds: number) => {
  return getNow() + seconds;
};
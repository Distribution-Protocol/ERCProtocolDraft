import { ethers } from 'ethers';
import { BigNumberish } from 'ethers';

export type CopyMintTuple = [string, BigNumberish, string, boolean, boolean, boolean, boolean];
export type CopyValidationTuple = [string, BigNumberish, boolean, BigNumberish, string, BigNumberish, BigNumberish, BigNumberish];

export interface CopyMintData {
    mintable: string,
    creatorId: BigNumberish;
    statement: string;
    transferable: boolean;
    updatable: boolean;
    revokable: boolean;
    extendable: boolean;
}

export interface CopyValidationData {
    feeToken: string;
    duration: BigNumberish;
    fragmented: boolean;
    mintAmount: BigNumberish;
    requiredERC721Token: string;
    limit: BigNumberish;
    start: BigNumberish;
    time: BigNumberish;
}

export const getMintData = (data: CopyMintData): CopyMintTuple => {
    return [
      data.mintable,
      data.creatorId,
      data.statement,
      data.transferable,
      data.updatable,
      data.revokable,
      data.extendable,
    ];
  };

export const getEncodedValidationData = (validationInfo: CopyValidationTuple) => {
return ethers.utils.defaultAbiCoder.encode(
    ['tuple(address, uint64, bool, uint256, uint256, address, uint256, uint64, uint64)'],
    [validationInfo]
    );
};

export const getCopyValidationData = (data: CopyValidationData): CopyValidationTuple => {
    return [
      data.feeToken,
      data.duration,
      data.fragmented,
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
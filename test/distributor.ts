import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { CONTENT, ZERO_ADDRESS } from '../utils/constants';
import { withSnapshot } from '../utils/helper';

import {
    getCopyValidationData,
    getEncodedValidationData,
    getNow
} from '../utils';

import { deploy } from '../scripts/deploy';
import { IContracts } from '../scripts/deploy.type';

withSnapshot('COPY Contract', () => {
  
    let owner: SignerWithAddress;
    let addr1: SignerWithAddress;
    let addr2: SignerWithAddress;
    let addr3: SignerWithAddress;
    let addrs: SignerWithAddress[];

    let contracts: IContracts;

    before(async function () {
        [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

        contracts = await deploy();
    });

    describe('end-to-end tests', async () => {

        it('Creator should be able to set up a Mintable Rule', async ()=> {

            // mint a token
            await contracts.mock.ERC721.connect(addr1).create(
                addr1.address,
                CONTENT.contentUri
            );

            // get creator Id
            let balance = (await contracts.mock.ERC721.balanceOf(addr1.address)).toNumber();
            let creatorId = (await contracts.mock.ERC721.tokenOfOwnerByIndex(addr1.address, balance-1)).toString();

            // mint rule
            let mintInfo = {
                validator: contracts.validator.address,
                nft: creatorId,
              };

            let valInfo = getCopyValidationData({
                feeToken: contracts.mock.ERC20.address,
                duration: 60 * 60 * 24 * 30,
                fragmented: true,
                mintAmount: 10000000000,
                requiredERC721Token: ZERO_ADDRESS,
                limit: 3,
                start: getNow()-1000,
                time: 99999999999999
            });

            // set mintable rule
            await contracts.distributor.connect(addr1).setDistributionRule(
                mintInfo,
                getEncodedValidationData(valInfo) // data
            );

            // original balance
            let walletBalance = await contracts.mock.ERC20.balanceOf(addr2.address);

            // copier go get some mockFT
            await contracts.mock.ERC20.connect(addr2).mint(addr2.address, 20000000000);

            // check balance
            expect((await contracts.mock.ERC20.balanceOf(addr2.address)).toNumber()).to.eq(walletBalance.add(20000000000));
            
            // set allowance
            await contracts.mock.ERC20.connect(addr2).approve(contracts.mintable.address, 10000000000);
            
            // get the copyHash
            let copyHash = (await contracts.distributor.getCopyHashes(creatorId))[0];

            // get a copy
            await contracts.distributor.connect(addr2).create(
                addr2.address,
                copyHash,
                60 * 60 * 24 * 30
                )
            
            // get copy Id
            let copyBalance = (await contracts.distributor.balanceOf(addr2.address)).toNumber();
            expect(copyBalance).to.gt(0);
            let copyId = (await contracts.distributor.tokenByIndex(copyBalance-1)).toString();

            // check balance after transaction
            expect((await contracts.mock.ERC20.balanceOf(addr2.address)).toNumber()).to.eq(walletBalance.add(10000000000));
            
            // check copy NFT data
            expect(await contracts.distributor.tokenURI(copyId)).to.eq(CONTENT.contentUri);
        })

        it('Creator should be able to set up a Mintable Rule with Help[er', async ()=> {
            
            // set Permission
            let permSig: PermSig = await getPermSig(addr1, CONTENT.contentUri, CONTENT.copyright, 1000000);
                
            // mint rule
            let mintInfo = {
                mintable: contracts.mintable.address,
                creatorId: 0, // dummy 
                statement: Statement.DISTRIBUTE,
                transferable: true,
                updatable: true,
                revokable: true,
                extendable: true,
                mintInfoAdditional: "0x"
            };
        
            let valInfo = getCopyValidationData({
                feeToken: contracts.mock.ERC20.address,
                duration: 60 * 60 * 24 * 30,
                fragmented: true,
                mintAmount: 10000000000,
                extendAmount: 10000000000,
                requiredERC721Token: ZERO_ADDRESS,
                limit: 3,
                start: getNow()-1000,
                time: 99999999999999
            });
            
            // mint and set rules
            await contracts.helper.connect(addr1).createWithMintables(
                addr1.address,
                CONTENT.contentUri,
                permSig,
                [mintInfo],
                [getEncodedValidationData(valInfo)] // data
            )

            // get creator Id
            let balance = (await contracts.creator.balanceOf(addr1.address)).toNumber();
            let creatorId = (await contracts.creator.tokenOfOwnerByIndex(addr1.address, balance-1)).toString();

            // original balance
            let walletBalance = await contracts.mock.ERC20.balanceOf(addr2.address);

            // copier go get some mockFT
            await contracts.mock.ERC20.connect(addr2).mint(addr2.address, 20000000000);

            // check balance
            expect((await contracts.mock.ERC20.balanceOf(addr2.address)).toNumber()).to.eq(walletBalance.add(20000000000));
            
            // set allowance
            await contracts.mock.ERC20.connect(addr2).approve(contracts.mintable.address, 10000000000);
            
            // get the copyHash
            let copyHash = (await contracts.distributor.getCopyHashes(creatorId))[0];
            
            // get a copy
            await contracts.distributor.connect(addr2).create(
                addr2.address,
                copyHash,
                60 * 60 * 24 * 30
                )
                
            // get copy Id
            let copyBalance = (await contracts.distributor.balanceOf(addr2.address)).toNumber();
            expect(copyBalance).to.gt(0);
            let copyId = (await contracts.distributor.tokenByIndex(copyBalance-1)).toString();

            // check balance after transaction
            expect((await contracts.mock.ERC20.balanceOf(addr2.address)).toNumber()).to.eq(walletBalance.add(10000000000));
            
            // check copy NFT data
            expect(await contracts.distributor.tokenURI(copyId)).to.eq(CONTENT.contentUri);
        })
 
    })
})
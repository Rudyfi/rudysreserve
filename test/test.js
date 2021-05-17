'use strict';


const BigNumber = require('bignumber.js');


//const assert = require('assert');



const Rudy = artifacts.require('./Rudy');


const RudyCrowdsale = artifacts.require("./RudyCrowdsale");







async function assertRevert (promise) {
  try {
    await promise;
  } catch (error) {
    ////console.log('revert', `Expected "revert", got ${error} instead`);
    return `Expected "revert", got ${error} instead`;
  }
  should.fail('Expected revert not received');
}





contract('ERC20', accounts => {

 

  it("Should deploy the token and burn some.", async function () {


    
    let RudyInstance = await Rudy.deployed();

    let RudyCrowdsaleInstance = await RudyCrowdsale.deployed();


    console.log("Address Rudy Token: "+RudyInstance.address)

    console.log("Address Rudy Launch: "+RudyCrowdsaleInstance.address)


    console.log("Address Owner: "+accounts[0])

    //set the launchpool
    RudyInstance.setRudy(RudyCrowdsaleInstance.address,{from:accounts[0],gas: 3000000,gasPrice: web3.utils.toWei("231", "gwei")});

    //console.log("Address launchpool: "+RudyCrowdsaleInstance.address)


    let balanceOfOwner = await RudyInstance.balanceOf(accounts[0]);
    let totalSupply = await RudyInstance.totalSupply();

    console.log("totalSupply : "+totalSupply)

    console.log("balanceOfOwner: "+balanceOfOwner)

    let balanceOfRudyb = await RudyInstance.balanceOf(RudyCrowdsaleInstance.address);
    console.log("balanceOfRudy : "+balanceOfRudyb)



    //cannot sent paused


    RudyInstance.transfer(accounts[6], web3.utils.fromWei("10", "wei"),{from:accounts[0],gas: 3000000,gasPrice: web3.utils.toWei("231", "gwei")});

    assertRevert(RudyInstance.transfer(accounts[7], web3.utils.fromWei("1", "wei"),{from:accounts[6],gas: 3000000,gasPrice: web3.utils.toWei("231", "gwei")}));

    //assert.strictEqual(ownerOfPlotICO,true)





    //send tokens to rudy
   

    RudyInstance.transfer(RudyCrowdsaleInstance.address, web3.utils.fromWei("100000000000000000000000", "wei"),{from:accounts[0],gas: 3000000,gasPrice: web3.utils.toWei("231", "gwei")});

    let balanceOfRudyl = await RudyInstance.balanceOf(RudyCrowdsaleInstance.address);
    console.log("balanceOfRudy after 'contribution' to launch: "+balanceOfRudyl)



    //contribute 1 bnb

    await web3.eth.sendTransaction({from: accounts[1],to: RudyCrowdsaleInstance.address, value: web3.utils.toWei("1","ether"), gas: 810000});


    let balanceOfRudyW = await RudyInstance.balanceOf(RudyCrowdsaleInstance.address);
    console.log("balanceOfRudy after someone 1 BNB: "+balanceOfRudyW)

    let balanceBuyer = await RudyInstance.balanceOf(accounts[1]);
    console.log("balanceBuyer after  1 BNB: "+balanceBuyer)


  // let balanceOfOwner2 = await RudyInstance.balanceOf(accounts[0]);
  // console.log("balanceOfOwner after burn: "+balanceOfOwner2)

  // let balanceOfRudy = await RudyInstance.balanceOf(accounts[1]);
  // console.log("balanceOfRudy after burn: "+balanceOfRudy)

  // let balance0 = await RudyInstance.balanceOf("0x0000000000000000000000000000000000000000");
  // console.log("balanceOf 0x0 after burn: "+balance0)
  
  let isHardcapreached = await RudyCrowdsaleInstance.hasEnded();

  assert.strictEqual(isHardcapreached,true)






  });


});


  



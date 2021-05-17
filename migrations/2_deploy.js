const Rudy = artifacts.require("Rudy");

const RudyCrowdsale = artifacts.require("RudyCrowdsale");



module.exports = (deployer, network, accounts) => {

	
	deployer.then(async () => {
	     
	       await deployer.deploy(Rudy,"0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F","0xBCfCcbde45cE874adCB698cC183deBcF17952812", {gasPrice: web3.utils.toWei("80", "gwei")});

	       await deployer.deploy(RudyCrowdsale, Rudy.address,{gasPrice: web3.utils.toWei("80", "gwei")});


	   });


  
  
  
  


  

}
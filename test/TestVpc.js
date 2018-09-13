var vpc = artifacts.require("vpc");

contract('vpc', function(accounts) {
	var verbose = true;  // set to true if need more logging

	it('adding registrant to the registrar', function(done){
        vpc.deployed().then(async function(instance) {
			// multiple payments
			await instance.deposit({from: accounts[0], value:1000000000000000000});
			await instance.deposit({from: accounts[0], value:4000000000000000000});
			await instance.deposit({from: accounts[0], value:5000000000000000000});
			await instance.deposit({from: accounts[0], value:2000000000000000000});
			await instance.deposit({from: accounts[1], value:13000000000000000000});
			// multiple payments
			await instance.deposit({from: accounts[2], value:1000000000000000000});
			await instance.deposit({from: accounts[2], value:1000000000000000000});
			await instance.deposit({from: accounts[2], value:1000000000000000000});
			await instance.deposit({from: accounts[2], value:7000000000000000000});
			await instance.deposit({from: accounts[2], value:1000000000000000000});
			await instance.deposit({from: accounts[2], value:1000000000000000000});
			await instance.deposit({from: accounts[2], value:0000000000000000000});
			await instance.deposit({from: accounts[3], value:12000000000000000000});
			await instance.deposit({from: accounts[4], value:13000000000000000000});
			await instance.deposit({from: accounts[5], value:12000000000000000000});
			await instance.deposit({from: accounts[6], value:12000000000000000000});

			// current registrants in the registry
			const registrants = await instance.getRegistrants();
			const num_registrants = await instance.getNumberRegistrants();
			const contract_balance = await instance.getBalance();
			const stake0 = await instance.getStake(accounts[0]);
			const stake2 = await instance.getStake(accounts[2]);

			let balance0 = await web3.eth.getBalance(accounts[0]);
			let balance1 = await web3.eth.getBalance(accounts[1]);
			let balance2 = await web3.eth.getBalance(accounts[2]);

			if(verbose) {
				console.log('current registrants ' + registrants);
				console.log('account: ' + accounts[0] + ' stake: ' + stake0);
				console.log('account: ' + accounts[2] + ' stake: ' + stake2);

				console.log('balance0 : ' + balance0.toNumber());
				console.log('balance1 : ' + balance1.toNumber());
				console.log('balance2 : ' + balance2.toNumber());
			}

			console.log("gasPrice: " + web3.eth.gasPrice);

			assert.equal(contract_balance.toNumber(), 86000000000000000000, 'Could not add registrant');
			assert.equal(num_registrants.toNumber(), 7, 'Could not add registrant');
			done();
       });
    });

/*
	it('deactivate registrant', function(done){
        vpc.deployed().then(async function(instance) {
			await instance.setRegistrantActive(accounts[0], false);
			// current registrants in the registrar
			const registrants = await instance.getRegistrants();
			const num_registrants = await instance.getNumberRegistrants();
			assert.equal(num_registrants.toNumber(), 6, 'Could not deactivate registrant');
			done();
       });
    });

	it('check if registrant is active', function(done){
        vpc.deployed().then(async function(instance) {
			const _false = await instance.isActiveRegistrant(accounts[0]);
			const _true = await instance.isActiveRegistrant(accounts[1]);
			assert.equal(_false, false, 'Cannot establish if registrant is active');
			assert.equal(_true, true, 'Cannot establish if registrant is active');
			done();
       });
    });
*/

	it('init channel', function(done){
	      vpc.deployed().then(async function(instance) {
				// current registrants in the registrar
				// const registrants = await instance.getRegistrants();
				// const num_registrants = await instance.getNumberRegistrants();
				var txlog = "";
				txlog = await instance.initChannel("0x424242424242424242", 5, {from: accounts[0]});
				console.log("initChannel with 5 verifiers gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
				txlog = await instance.initChannel("0x434343434343434343", 5, {from: accounts[1]});
				console.log("initChannel with 5 verifiers gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
				txlog = await instance.initChannel("0x444444444444444444", 2, {from: accounts[2]});
				console.log("initChannel with 2 verifiers gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
				txlog = await instance.initChannel("0x454545454545484545", 7, {from: accounts[3]});
				console.log("initChannel with 7 verifiers gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
				txlog = await instance.initChannel("0x464646464646464646", 5, {from: accounts[4]});
				console.log("initChannel with 5 verifiers gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
				txlog = await instance.initChannel("0x474747474747474747", 5, {from: accounts[5]});
				console.log("initChannel with 5 verifiers gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
				txlog = await instance.initChannel("0x484848484848484848", 5, {from: accounts[6]});
				console.log("initChannel with 5 verifiers gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));

				const num_channels = await instance.getNumberOfChannels();
				console.log("initiated channels=" + num_channels.toNumber());
				done();
	      });
   });


it('channel info', function(done){
 	      vpc.deployed().then(async function(instance) {
 				const channel_info = await instance.getChannel("0x444444444444444444");
 				console.log("channel_info=" + channel_info);
 				const verifiers = await instance.getVerifiers("0x444444444444444444");
 				console.log("verifiers=" + verifiers);
 				done();
 	      });
    });

it('submit proofs for a model_id', function(done){
		 vpc.deployed().then(async function(instance) {
			var sigs = ["0xabcd", "0xbcda", "0xcdefa"];
			const model_id = "0x444444444444444444"
			const merkle_root = "0x123456"
			var txlog = "";

	  	txlog = await instance.submitProof(model_id, merkle_root, sigs, {from: accounts[0]});
			console.log("submitProof from account[0] gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
			txlog = await instance.submitProof(model_id, merkle_root, sigs, {from: accounts[1]});
			console.log("submitProof from account[1] gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
			txlog = await instance.submitProof(model_id, "0x123458", sigs, {from: accounts[2]});
			console.log("submitProof from account[2] gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
			txlog = await instance.submitProof(model_id, "0x123459", sigs, {from: accounts[3]});
			console.log("submitProof from account[3] gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
			txlog = await instance.submitProof(model_id, "0x123459", sigs, {from: accounts[4]});
			console.log("submitProof from account[4] gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
			txlog = await instance.submitProof(model_id, "0x123459", sigs, {from: accounts[5]});
			console.log("submitProof from account[5] gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));
			txlog = await instance.submitProof(model_id, "0x123459", sigs, {from: accounts[6]});
			console.log("submitProof from account[6] gasUsed=" + JSON.stringify(txlog.receipt.gasUsed));

		 	const num_proofs = await instance.getProofCount(model_id);
		 	console.log("model_id=" + model_id + " num_proofs=" + num_proofs);

			const proofs_list = await instance.getProofsList(model_id);
			console.log("model_id=" + model_id + " proofsList=" + proofs_list);

			const proof = await instance.getProof(model_id, "0x8eba7f5dd14a248afafcc5fd7d09d697851aba2914e933944a3907ceacbaf95c");
			console.log("proof=" + proof);

			const counter = await instance.getValidationInfo(model_id, merkle_root);
			console.log("counter of " + merkle_root + "=" + counter);

			const is_valid = await instance.isPotValid(model_id);
			console.log("model_id=" + model_id + " valid=" + is_valid);

			done();
		 });
 });

});

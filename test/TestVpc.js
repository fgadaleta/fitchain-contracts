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

				await instance.init_channel("0x424242424242424242", 5);
				await instance.init_channel("0x434343434343434343", 5);

				await instance.init_channel("0x444444444444444444", 2);

				await instance.init_channel("0x454545454545484545", 7);
				await instance.init_channel("0x464646464646464646", 5);
				await instance.init_channel("0x474747474747474747", 5);
				await instance.init_channel("0x484848484848484848", 5);
				const num_channels = await instance.getNumberOfChannels();
				console.log("initiated channels=" + num_channels.toNumber());

				//const channel_info = await instance.getChannel("0x454545454545484545");
				//console.log("channel_info=" + channel_info);

				//const verifiers = await instance.getVerifiers("0x4444444444444444444444");
				//console.log("verifiers=" + verifiers);

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

		/*
	it('get eligible proposer', function(done){
	      vpc.deployed().then(async function(instance) {
					// current registrants in the registrar
					const registrants = await instance.getRegistrants();
					const num_registrants = await instance.getNumberRegistrants();
					const idx = await instance.getEligibleProposer();
					console.log('current registrants ' + registrants);
					console.log('selected proposer address ' +  JSON.stringify(idx) );
					done();
	       });
	    });
*/

it('submit proofs for a model_id', function(done){
		 vpc.deployed().then(async function(instance) {
			var sigs = ["0xabcd", "0xbcda", "0xcdefa"];
			const model_id = "0x444444444444444444"
			const merkle_root = "0x123456"
	  	await instance.submitProof(model_id, merkle_root, sigs);
			await instance.submitProof(model_id, merkle_root, sigs);
			await instance.submitProof(model_id, "0x123458", sigs);
			await instance.submitProof(model_id, "0x123459", sigs);

		 	const num_proofs = await instance.getProofCount(model_id);
		 	console.log("model_id=" + model_id + " num_proofs=" + num_proofs);

			const proofs_list = await instance.getProofsList(model_id);
			console.log("model_id=" + model_id + " proofsList=" + proofs_list);

			const proof = await instance.getProof(model_id, "0x8eba7f5dd14a248afafcc5fd7d09d697851aba2914e933944a3907ceacbaf95c");
			console.log("proof=" + proof);
			done();
		 });
 });

});

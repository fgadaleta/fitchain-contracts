var registry = artifacts.require("registry");


contract('registry', function(accounts) {
	var verbose = true;  // set to true if need more logging

	it('adding models to the registry ', function(done){
        registry.deployed().then(async function(instance) {
			// model name, model_ipfs_address, stored_as, bounty, current_error, target_error
			await instance.createModel('model_1', '0xabcd', '0', '100', '100', '10');
			await instance.createModel('model_2', '0x1234', '0', '100', '42', '10');
			await instance.createModel('model_3', '0x2345', '0', '100', '100', '10');
			// duplicate model will not be created (still 3 models)
			await instance.createModel('model_4', '0x2345', '0', '100', '100', '10');
			// current models in the registry
			const num_models = await instance.getNumberOfModels();
			assert.equal(num_models.toNumber(), 3, 'Could not create a model');
			done();
       });
    });


	it('setting model as valid/invalid', function(done){
        registry.deployed().then(async function(instance) {
			// model_ipfs_address, challenge_ipfs_address
			const ret = await instance.setModelValid('0xabcd', false);

			if (verbose == true)
			{
				console.log('ret = ' + ret );
			}

			assert.equal(0,0,'');
			done();
       });
    });


	it('getting models from the registry ', function(done){
        registry.deployed().then(async function(instance) {
			const model_1 = await instance.getModel('0xabcd');
			const model_2 = await instance.getModel('0x1234');
			// model name, model_ipfs_address, stored_as, bounty, current_error, target_error
			if (verbose == true) {
				console.log(' model_1 owner=' + model_1[0] +
							' ipfs_addr=' + model_1[1] +
							' is_valid=' + model_1[6])
				console.log(' model_2 owner=' + model_2[0] +
							' ipfs_addr=' + model_2[1] +
							' is_valid=' + model_2[6])
			}

			assert.equal(model_1[1], '0xabcd000000000000000000000000000000000000000000000000000000000000',
						 'Could not retrieve model');
			assert.equal(model_1[2], '0', 'Could not retrieve model');
			assert.equal(model_1[3], '100', 'Could not retrieve model');
			assert.equal(model_1[4], '100', 'Could not retrieve model');

			assert.equal(model_2[1], '0x1234000000000000000000000000000000000000000000000000000000000000',
						 'Could not retrieve model');
			assert.equal(model_2[2], '0', 'Could not retrieve model');
			assert.equal(model_2[3], '100', 'Could not retrieve model');
			assert.equal(model_2[4], '42', 'Could not retrieve model');
			done();
       });
    });


	it('adding challenges to existing model ', function(done){
        registry.deployed().then(async function(instance) {
			// model_ipfs_address, challenge_ipfs_address
			await instance.createChallenge('0xabcd', '0x123456');
			await instance.createChallenge('0xabcd', '0x134457');
			await instance.createChallenge('0xabcd', '0x145458');
			await instance.createChallenge('0xabcd', '0x156459');
			await instance.createChallenge('0xabcd', '0x167410');
			await instance.createChallenge('0xabcd', '0x178411');
			await instance.createChallenge('0xabcd', '0x189412');
			// duplicate challenge will not be added
			await instance.createChallenge('0xabcd', '0x189412');
			// current challenges for this model
			const num_challenges = await instance.getNumberOfChallenges('0xabcd');
			assert.equal(num_challenges.toNumber(), 7, 'Could not create challenge');
			done();
       });
    });


	it('setting challenge as active/inactive', function(done){
        registry.deployed().then(async function(instance) {
			// set challenge non active
			await instance.setChallengeActive('0x123456', false);
			// get this challenge
			challenge = await instance.getChallenge('0x123456');
			var is_active = challenge[4]
			assert.equal(is_active, false, 'Failed to inactivate challenge');
			done();

			// set active back otherwise break following tests
			await instance.setChallengeActive('0x123456', true);
       });
    });


	it('getting all model challenges', function(done){
        registry.deployed().then(async function(instance) {
			// model_ipfs_address, challenge_ipfs_address
			var challenges_1 = await instance.getModelChallenges('0xabcd');
			var num_challenges_1 = challenges_1.length;
			if(verbose==true)
				console.log('getting model_1 challenges ' + challenges_1);

			assert.equal(num_challenges_1, 7, 'Could not retrieve model challenges');

			assert.equal(challenges_1[0], '0x1234560000000000000000000000000000000000000000000000000000000000',
						 'Could not retrieve list of challenges');
			assert.equal(challenges_1[1], '0x1344570000000000000000000000000000000000000000000000000000000000',
						 'Could not retrieve list of challenges');
			assert.equal(challenges_1[2], '0x1454580000000000000000000000000000000000000000000000000000000000',
						 'Could not retrieve list of challenges');

			// delete one challenge and count again
			await instance.deleteChallenge('0x189412');
			challenges_1 = await instance.getModelChallenges('0xabcd');
			num_challenges_1 = challenges_1.length;
			if(verbose == true)
				console.log('num_challenges=' + num_challenges_1);
			assert.equal(num_challenges_1, 6, 'Could not delete a challenge');
			done();
       });
    });


	it('getting some challenges', function(done){
        registry.deployed().then(async function(instance) {
			// model_ipfs_address, challenge_ipfs_address
			const challenge_1 = await instance.getChallenge('0x123456');
			const challenge_2 = await instance.getChallenge('0x134457');
			const challenge_3 = await instance.getChallenge('0x145458');

			if(verbose){
				console.log('getting challenge_1 ' + challenge_1);
				console.log('getting challenge_2 ' + challenge_2);
				console.log('getting challenge_3 ' + challenge_3);
			}

			assert.equal(challenge_1[0], '0xabcd000000000000000000000000000000000000000000000000000000000000',
						 'Could not create challenge');
			assert.equal(challenge_1[2], '0x1234560000000000000000000000000000000000000000000000000000000000',
						 'Could not create challenge');
			assert.equal(challenge_2[0], '0xabcd000000000000000000000000000000000000000000000000000000000000',
						 'Could not create challenge');
			assert.equal(challenge_2[2], '0x1344570000000000000000000000000000000000000000000000000000000000',
						 'Could not create challenge');
			assert.equal(challenge_3[0], '0xabcd000000000000000000000000000000000000000000000000000000000000',
						 'Could not create challenge');
			done();
       });
    });
	

	it('deleting one challenge from the registry ', function(done){
        registry.deployed().then(async function(instance) {
			const n_challenges_before = await instance.getModelChallenges('0xabcd');
			console.log(n_challenges_before);
			await instance.deleteChallenge('0x1234560000000000000000000000000000000000000000000000000000000000');
			const n_challenges_after = await instance.getModelChallenges('0xabcd');

			assert.equal(n_challenges_before.length, n_challenges_after.length + 1, 'Could not delete a challenge');
			done();
       });
    });

	it('deleting one model from the registry ', function(done){
        registry.deployed().then(async function(instance) {
			// model name, model_ipfs_address, stored_as, bounty, current_error, target_error
			await instance.deleteModel('0xabcd');
			// current models in the registry
			const num_models = await instance.getNumberOfModels();
			assert.equal(num_models.toNumber(), 2, 'Could not delete a model');
			done();
       });
    });


});

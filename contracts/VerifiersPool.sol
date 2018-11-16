pragma solidity ^0.4.25;
import "./GossipersPool.sol";
import "./FitchainLib.sol";

// https://www.reddit.com/r/ethdev/comments/6lbmhy/a_practical_guide_to_cheap_ipfs_hash_storage_in/

/*
 * Start geth on rinkeby
 * geth --rinkeby --rpc --rpccorsdomain "http://localhost:8080" console
 * geth --rinkeby --rpc --rpccorsdomain "*" --ws --wsorigins="*" --unlock 0x95d4ca7b9c8cc4f00871d95378f94ca24197ee2e console
 *
*/

contract Registry {

    GossipersPool registrar = GossipersPool(registrarAddress);

    // Address of the fitchainRegistrar contract which holds all the Registrants
    address public registrarAddress;
    // Address of the account which deployed the contract. Used only to configure contract.
    address public deployerAddress;

	/*****************************
	 *  model_metric events      *
	 ****************************/

	//////////////////////////////////////////////////////////////////////////////
	// TODO make obsolete when using state channel
	event EntityCreated(address owner,bytes32 entityType,
						bytes32 entityId, bytes32 ipfs);
    event EntityArchived(address owner, bytes32 entityType, bytes32 entityId);
    event LogCreated(bytes32 project, bytes32 workspace, bytes32 job,
					 uint timestamp, bytes32 channel, string payload);
    event MetricCreated(address user, bytes32 project, bytes32 workspace,
						bytes32 job, uint timestamp, bytes32 key, bytes32 value);
    event WorkspaceCreated(uint timestamp, address user, bytes32 project);


	function createEntity(bytes32 entityType, bytes32 entityId, bytes32 ipfs) public {
        EntityCreated(msg.sender, entityType, entityId, ipfs);
    }

    function archiveEntity(bytes32 entityType, bytes32 entityId ) public {
        EntityArchived(msg.sender, entityType, entityId);
    }

    function workOnProject(uint timestamp, bytes32 projectId) public {
        WorkspaceCreated(timestamp, msg.sender, projectId);
    }

    function createLog(bytes32 project, bytes32 workspace, bytes32 job, uint timestamp,
        bytes32 channel, string payload ) public {
        LogCreated(project, workspace, job, timestamp, channel, payload);
    }

    function createMetric(bytes32 project, bytes32 workspace, bytes32 job,
						  uint timestamp, bytes32 key, bytes32 value) public {
        MetricCreated(msg.sender, project, workspace, job, timestamp, key, value);
    }

	/////////////////////////////////////////////////////////////////////////////////

	/*****************************
	 *  registry events          *
	 ****************************/

    /*
    * Creation event that gets triggered when a model is created.
    * event
    * @param ids - The identity of the thing.
    * @param owner - The owner address.
    */
    event Created(bytes32 id, address indexed owner);

    /*
    * Update event that gets triggered when a model is updated.
    * event
    * @param ids - The identity of the thing.
    * @param owner - The owner address.
    * @param isValid - The validity of the thing.
    */
    event Updated(bytes32 id, address indexed owner, bool isValid);

    /*
    * Delete event, triggered when Thing is deleted.
    * event
    * @param ids - The identity of the thing.
    * @param owner - The owner address.
    */
    event Deleted(bytes32 id);

    /*
    * Generic error event.
    * event
    * @param code - The error code.
    * @param reference - Related references data for the Error event, e.g.: Identity, Address, etc.
    * 1: Identity collision, already assigned to another Thing.
    * 2: Not found, identity does not exist.
    * 3: Unauthorized, modification only by owner.
    * 4: Unknown schema specified.
    * 5: Incorrect input, at least one identity is required.
    * 6: Incorrect input, data is required.
    * 7: Incorrect format of the identity, schema length and identity length cannot be empty.
    * 8: Incorrect format of the identity, identity must be padded with trailing 0s.
    * 9: Contract already configured
    * 10: Challenge already closed
    */
    event Error(uint code);

	//uint256 max_int = 2**256;

	/* data structures */
	struct Model {
		// identity of a model, eg.public key, architecture_hash, model_params_hash,etc.
		bytes identity;
		// Registrant address, who submitted the model
		address ownerAddress;
		// where it is stored
		bytes32 ipfsAddress;
		// format it is stored
		uint storedAs; // 0:str, 1:bytes, 2:pyobj
		uint bounty;
		uint currentError;
		uint targetError;
		// Status of the Thing. false if compromised, revoked, etc.
		bool isValid;
    }

    // Models are stored in array
    Model[] public models;
    // Identity to model index pointer for lookups and duplicates prevention
    mapping(bytes32 => uint) public idToModel;

    struct Challenge {
        bytes32 modelIdentity;   // model identity this challenge belongs to
        address verifierAddress; // Verifier address
        bytes32 ipfsAddress;     // IPFS address of validation data for this challenge
        uint errorMetric;        // 0:elementwise match, 1:elementwise distance, 2:mse
        uint validationResult;   // depends on errorMetric (accuracy, error_rate)
        bool isActive;           // challenge can be closed only by smart contract
        uint256 timestamp;
        bytes32[] validatorAddress;
    }

    // Challenges are stored in the array
    Challenge[] public challenges;

    // Identity to Challenge index pointer for lookups and duplicates prevention
    mapping(bytes32 => uint) public idToChallenge;
    mapping(bytes32 => bytes32[]) public modelToChallenges;

    struct Validator {
        address validatorAddress;
        uint deposit;
        bool isActive;
        uint reputationScore;
    }

    /*
    * Function can't contain Ether value.
    * modifier
    */
    modifier noEther() {
      if (msg.value > 0) revert();
      _;
    }

    /*
    * Allow only registrants to exec the function.
    * modifier
    */
    modifier isRegistrant() {
    // TODO uncomment this in production
    /*
    fitchainRegistrar registrar = fitchainRegistrar(registrarAddress);
      if (registrar.isActiveRegistrant(msg.sender)) {
	_;
      }
      */
    _;
    }

    /*
    * Allow only registrar to exec the function.
    * modifier
    */
    modifier isRegistrar() {
    // TODO uncomment this in production
     /* fitchainRegistrar registrar = fitchainRegistrar(registrarAddress);
      if (registrar.registrar() == msg.sender) {
	_;
      }
      */
      _;
    }

    modifier onlyByModelOwner(uint gradientId) {
        //require(msg.sender == models[grads[gradientId].modelId].owner);
        _;
  }

    /*
    * Initialization of the contract constructor
    */
    constructor() public payable {
      // Initialize arrays. Leave first element empty, since mapping points non-existent keys to 0.
      models.length++;
      challenges.length++;
      deployerAddress = msg.sender;
    }

    // WIP
    function voteModel(bytes model_id, uint vote) public payable {
        // need to be a verifier to vote a challenge
        require(registrar.isActiveRegistrant(msg.sender) == true);

    }

    // TODO add timestamps
    // otherwise a verifier can create and verify indefinitely
    /*
    * @param thing_id - identity of the thing to prove
    * @param challengeHash - identity of the challenge to prove
    * @param output - values of the proof
    */
    /*
    function proveChallenge(bytes32 thing_id, bytes32 challengeHash, bytes32[] output) public returns(uint) {
        uint matched=0;
        // search in dictionary if challenge already exists
        bytes32 idHash = keccak256(thing_id);
        uint index = idToThing[idHash];
        // Thing not found
        if (index == 0)
            {
        	  Error(2);
        	  return;
        	}

        index = idToChallenge[challengeHash];
        // challenge to prove not found
        if (index == 0)
    	{
    	  Error(2);
    	  return;
    	}
    	// set proverClaim with output
    	Challenge storage this_challenge = challenges[index];
    	// this challenge has terminated
    	if (this_challenge.active == false){
    	    Error(10);
    	    return;
    	}
    	// mismatch between prover claim and verifier claim
    	if (output.length != this_challenge.output.length){
    	    Error(7);
    	    return;
    	}

    	this_challenge.proverClaim = output;
    	for(uint i=0; i< output.length; i++){
    	    if(output[i] == this_challenge.output[i]) matched++;
    	}
    	// deactivate this challenge
    	this_challenge.active = false;
    	return matched;
    }
    */

    /*
     * Create challenge for model thing_id
     * @return challenge unique id on success, 0x0 otherwise
    */
    function createChallenge(bytes32 model_id, bytes32 ipfs_address)
		public returns(bytes32)
    {
		// TODO should not create challenge of non valid model

        // check that thing to be challenged exists
        uint modelIndex = idToModel[model_id];
        // model to be challenged does not exist
        if(modelIndex == 0){
            emit Error(2);
	        return;
        }
        // search in dictionary if challenge already exists
        uint index = idToChallenge[ipfs_address];
        // Challenge with such ID already exists
        if (index > 0)
    	{
    	  //Error(1);
    	  // return instead the existing challengeHash
    	  return ipfs_address;
    	}

        // Now after all verifications passed we can add the challenge
        uint pos = challenges.length++;
        // Creating structure in-place is 11k gas cheaper than assigning parameters separately.
        // That's why methods like updateThingData, addIdentities are not reused here.
        challenges[pos] = Challenge(model_id,
                                    msg.sender,
                                    ipfs_address,
                                    0, 0,
                                    true,
                                    now,
                                    new bytes32[](0x0)
                                    );
        // Update index
        idToChallenge[ipfs_address] = pos;
        bytes32[] storage model_challenges = modelToChallenges[model_id];
        // add pos of this new challenge to model_challenges mapping
        model_challenges.push(ipfs_address);
        // "Broadcast" event
        emit Created(ipfs_address, msg.sender);
        return ipfs_address;
    }

    /*
    * Create model without duplicates
    * <bytes> model_id name of the thing to create
    * <bytes32> ipfs address where thing is stored
    * <uint> stored_as how to store thing 0:str, 1:bytes, 2:pyobj
    * @return bool - success or fail
    */
    function createModel(bytes model_id,
                         bytes32 ipfs_address,
                         uint stored_as,
                         uint bounty,
                         uint current_error,
                         uint target_error) payable public returns(bool) {

      //cannot create two models with different id pointing to same ipfs address
      //bytes32 idHash = FitchainLib.getSomethingHash("","", ipfs_address);
      //bytes32 idHash = ipfs_address; //keccak256(ipfs_address);
      uint index = idToModel[ipfs_address];
      // model already exists
      if (index > 0)
        {
    	  emit Error(1);
    	  return false;
    	}

      // Now after all verifications passed we can add the Thing
      uint pos = models.length++;
      // Creating structure in-place is 11k gas cheaper than assigning parameters separately.
      // That's why methods like updateThingData, addIdentities are not reused here
      models[pos] = Model(model_id, msg.sender,
                          ipfs_address,
                          stored_as,
                          bounty, current_error, target_error,
                          true);
      // Update index
      idToModel[ipfs_address] = pos;

      // init list of challenges for this model
      modelToChallenges[ipfs_address] = new bytes32[](0x0);

      // "Broadcast" event
      emit Created(ipfs_address, msg.sender);
      return true;
    }

    function getNumberOfModels() public constant returns (uint numberOfModels) {
      // FIXME are we sure of this -1??
      return models.length - 1;

    }

    /*
    * Return number of challenges of model_id
    * @param thing_id - id of thing to count active challenges of
    */
    function getNumberOfChallenges(bytes32 model_id) public constant returns (uint) {
      uint index = idToModel[model_id];
      // model not found
      if (index == 0) {
    	emit Error(2);
    	return;
      }
      return modelToChallenges[model_id].length;
    }

    /*
    * Get model's information
    * constant_function
    * @param model_id - identity of the thing.
    */
    function getModel(bytes32 model_id) public constant returns(address, bytes32, uint, uint, uint, uint, bool) {
      //uint index = idToThing[keccak256(thing_id)];
      uint index = idToModel[model_id];
      // thing not found
      if (index == 0) {
    	emit Error(2);
    	return;
      }

      Model memory model = models[index];
      return (model.ownerAddress,
              model.ipfsAddress,
              model.storedAs,
              model.bounty,
              model.currentError,
              model.targetError,
              model.isValid);
    }

    /*
    * Given challenge unique id, return all fields of this challenge
    * @param id - hash(model_id + input)
    */
    function getChallenge(bytes32 challenge_hash)
		public constant returns(bytes32 model_identity,
								address verifier_address,
								bytes32 ipfs_address,
								uint error_metric,
								bool is_active,
								bytes32[] validator_address) {
		//Challenge memory challenge = challenges[index];
		uint index = idToChallenge[challenge_hash];

		// TODO return not found error

		Challenge memory challenge = challenges[index];
		model_identity    = challenge.modelIdentity;
		verifier_address  = challenge.verifierAddress;
		ipfs_address      = challenge.ipfsAddress;
		error_metric      = challenge.errorMetric;
		is_active         = challenge.isActive;
		validator_address = challenge.validatorAddress;
    }

    /*  Return all active challenge hash(es) of this model_id
     *
    */
    function getModelChallenges(bytes32 model_id) public constant returns(bytes32[]){
        uint index = idToModel[model_id];
        if (index == 0) {
            emit Error(2);
            return;
        }

        // challenge indexes of this thing
        bytes32[] active_challenges;
        bytes32[] memory all_challenges_id = modelToChallenges[model_id];

        for (uint i=0; i<all_challenges_id.length; i++) {
            var(model_identity,verifier_address,ipfs_address, error_metric, is_active, validator_address) = getChallenge(all_challenges_id[i]);
            if(is_active)
                active_challenges.push(ipfs_address);
        }
        return active_challenges;
	}

    /*
    * Delete previously added model
    * @param model_id - model identity to delete
    */
    function deleteModel(bytes32 model_id) public isRegistrant noEther returns(bool) {
		// FIXME
		uint index = idToModel[model_id];
		// not found
		if (index == 0) {
			emit Error(2);
			return;
		}

		// not authorized
		if (models[index].ownerAddress != msg.sender) {
			emit Error(3);
			return;
		}

		// delete all challenges of this thing or invalidate them
		bytes32[] memory model_to_challenges = getModelChallenges(model_id);
		uint num_challenges = model_to_challenges.length;

		// deactivate all challenges
		for (uint i=0; i<num_challenges; i++) {
			bytes32 ch = model_to_challenges[i];
			deleteChallenge(ch);
		}

		// set index to 0
		idToModel[model_id] = 0;
		// Put last element in place of deleted one
		if (index != models.length - 1) {
			// Move last model to the place of deleted one.
			models[index] = models[models.length - 1];
		}
		// Delete last model
		models.length--;
		// "Broadcast" event with identities before they're lost.
		emit Deleted(model_id);
		return true;
    }

    function deleteChallenge(bytes32 challenge_id) public isRegistrant noEther returns(bool) {
		uint index = idToChallenge[challenge_id];
		// not found
		if (index == 0) {
			emit Error(2);
			return;
		}

		// not authorized
		if (challenges[index].verifierAddress != msg.sender) {
			emit Error(3);
			return;
		}

		// set index to 0
		idToChallenge[challenge_id] = 0;

		// Put last element in place of deleted one
		if (index != challenges.length - 1) {
			// Move last challenge to the place of deleted one
			uint last_challenge_idx = challenges.length -1 ;
			challenges[index] = challenges[last_challenge_idx];
		}

		// Delete last challenge
		//challenges.length--;
		emit Deleted(challenge_id);
		return true;
    }


    /*
    * Set validity of a model, only registrants allowed.
    * public_function
    * @param _id - The model to change.
    * @param _isValid - The new validity flag of the model.
    */
    function setModelValid(bytes32 model_id, bool is_valid) public isRegistrant noEther constant returns(bool) {
        uint index = idToModel[model_id];

	    // not found
        if (index == 0) {
            emit Error(2);
            return false;
        }
	    // not authorized
        if (models[index].ownerAddress != msg.sender) {
            emit Error(3);
            return false;
        }
        // set valid field
        models[index].isValid = is_valid;

        // Broadcast event
        emit Updated(model_id, models[index].ownerAddress, models[index].isValid);
        return true;
    }

    /*
    * Set challenge active/non_active, only registrants allowed.
    * public_function
    * @param challenge_id - The identity to change flag of
    * @param is_active - The new validity of the challenge
    */
    function setChallengeActive(bytes32 challenge_id, bool is_active) public isRegistrant noEther returns(bool) {
        uint index = idToChallenge[challenge_id];

	    // not found
        if (index == 0) {
            emit Error(2);
            return false;
        }
	    // not authorized
        if (challenges[index].verifierAddress != msg.sender) {
            emit Error(3);
            return false;
        }

        // set valid field
        challenges[index].isActive = is_active;

        // Broadcast event
        emit Updated(challenge_id,
                challenges[index].verifierAddress,
                challenges[index].isActive);
        return true;
    }
}
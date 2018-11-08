pragma solidity ^0.4.25;
import "./fitchainLib.sol";
// import "./Dictionary.sol";

contract Vpc {
  uint MIN_STAKE         = 12000000000000000000;   // min stake in wei (12 eth)
  uint VERIFIER_QUOTA    = 1000;
  uint MIN_NUM_VERIFIERS = 1;  // FIXME change_me
  address public registrar;                        // address of account who inits

  // using Dictionary for Dictionary.Data;

  event Created(address registrant, uint stake);
  event Updated(address indexed registrant, address registrar, bool active);
  event Withdrawn(address addr);
  event InitChannel(bytes32 channel_id);

  /**
   * Error event.
   * event
   * @param code - The error code
   * 1: Permission denied
   * 2: Duplicate Registrant address
   * 3: No such Registrant
   * 4: Min stake not reached
   * 5: Max number of verifiers allowed
   * 6: Proof already submitted
   */
  event Error(uint code);

  // Registrant -> Validator
  struct Registrant {
	  address addr;
	  uint stake;
	  bool active;
  }
  mapping(address => uint) public registrantIndex;
  mapping(address => bool) public registrantBusy;  // a verifier is assigned to a channel
  Registrant[] public registrants;

  // one channel is initialized for one model
  struct Channel {
    bytes32 channel_id;   // assigned by contract
    bytes32 model_id;     // model to be verified in this channel
    uint k;               // proofs in this channel require k sigs
  }

  mapping(bytes32 => address[]) public channelVerifiers;
  mapping(bytes32 => bool) public isChannelActive;
  mapping(bytes32 => Channel) public channelStructs;
  bytes32[] public channelList;

  // Data structure containing the single proof for a model
  struct Proof {
    address sender;      // verifier who submitted this proof
		bytes32 merkle_root; // Merkle-root of the training logs
    bytes32[] sigs;      // list of signatures provided by verifiers
  }

  struct Pot {
    bytes32[] proofsList;   // list of proofs'keys we can look up (sumbitted by verifiers)
    mapping(bytes32 => Proof) proofStructs;
    mapping(bytes32 => bool) proofsSubmitted;
    mapping(bytes32 => uint) merkle_counters;
  }

  mapping(bytes32 => Pot) potStructs;  // random access by model_id to proof of training
  // Pot[] pots; // not used
  // mapping(bytes32 => bytes32[]) pots;  // model_id to merkle_roots

  /**
   * no ether accepted for this tx
   */
  modifier noEther() {
    if (msg.value > 0) revert();
    _;
    }

  modifier isRegistrar() {
      if (msg.sender != registrar) {
        emit Error(1);
        return;
      }
      else {
        _;
      }
    }

  /**
   * Construct registry with and starting registrants lenght of one,
   * and registrar as msg.sender
   */
  constructor() public{
    registrar = msg.sender;
    registrants.length++;
    }

  // submit_proof(service_id, model_id, merkleroot, tx_eot, sig, sender_addr)
  // bytes32, bytes32, string, string, bytes, address

  // submit proof of training to model
  function submitProof(bytes32 service_id, bytes32 model_id, string merkleroot, string eot,  bytes sig, address sender) returns (bool) {
      require(isChannel(model_id));
      Proof memory prf;
      prf.sender = msg.sender;
      prf.merkle_root = merkleroot;
      prf.sigs = sigs;

      // FIXME
      // proof key = hash(sender + model_id + merkle_root)
      // sender + merkle_root should be enough because we store it to potStructs[model_id]
      // there we go with the pot hash :)
      bytes memory pot_hash = fitchainLib.concatenate3(bytes32(msg.sender), model_id, merkle_root);
      bytes32 prf_key = keccak256(pot_hash);

      // check if this proof has been submitted already
      bool prf_exist = potStructs[model_id].proofsSubmitted[prf_key];
      if(prf_exist == true){
          emit Error(6);
          return false;
      }

      potStructs[model_id].proofsList.push(prf_key);
      potStructs[model_id].proofStructs[prf_key] = prf;
      potStructs[model_id].proofsSubmitted[prf_key] = true;
      // update merkle counter for this pot
      uint count = potStructs[model_id].merkle_counters[merkle_root];
      potStructs[model_id].merkle_counters[merkle_root] = count+1;

      // TODO
      // check number of current submissions
      // call isPotValid() (rename to isPotGood? :)

      return true;
    }

  // given model_id returns the number of submitted proofs
  function getProofCount(bytes32 model_id) public constant returns(uint) {
    return potStructs[model_id].proofsList.length;
    }

  // given the model_id return the list of proof keys
  function getProofsList(bytes32 model_id) public constant returns(bytes32[]) {
    require(isChannel(model_id));
    return potStructs[model_id].proofsList;
  }

  // given proof_key return the proof fields
  // TODO make this internal
  function getProof(bytes32 model_id, bytes32 proof_key) public constant returns(address, bytes32, bytes32[]) {
    require(isChannel(model_id));
    Proof memory proof = potStructs[model_id].proofStructs[proof_key];
    return (proof.sender, proof.merkle_root, proof.sigs);
    }

  // !!WORK IN PROGRESS!! given model_id returns bool if model is verified by consensus (valid Pot)
  function isPotValid(bytes32 model_id) public constant returns(bool, uint) {
    // get channel from model_id
    // get channel.verifiers and channel.k
    // get pot from pot.model_id
    // check that +k sigs in pot.proofs
    var (m_id, k) = getChannel(model_id);

    // TODO count number of equal merkle roots reached super-majority
    bytes32[] memory proof_keys = getProofsList(model_id);

    for(uint i=0; i<proof_keys.length; i++){
      var (prf_sender, prf_merkleroot, prf_sigs) = getProof(model_id, proof_keys[i]);
        // TODO check sender is in verifiers of this channel

        // TODO check that sigs belong to verifiers of this channel

        // count how many verifiers proposed this merkle root
        uint count = potStructs[model_id].merkle_counters[prf_merkleroot];
        // FIXME super-majority 51% is enough
        if(count > k-1) {
          return (true, count);
        }
    }
    return (false, 0);
  }

  function getValidationInfo(bytes32 model_id, bytes32 merkle_root) public constant returns(uint) {
    return potStructs[model_id].merkle_counters[merkle_root];
    }

  function isChannel(bytes32 check) public view returns(bool isIndeed) {
   return isChannelActive[check];
    }

  function initChannel(bytes32 model_id, uint k) returns (bool success) {
    require(!isChannel(model_id));
    require(k > MIN_NUM_VERIFIERS);

    bytes32 channel_id = model_id;

    channelList.push(channel_id);
    channelStructs[channel_id].channel_id = channel_id;
    channelStructs[channel_id].model_id = model_id;
    channelStructs[channel_id].k = k;
    isChannelActive[model_id] = true;
    // allocate verifiers to this channel
    channelVerifiers[channel_id] = new address[](0x0);

    // allocate proof of training for the model in this channel
    potStructs[model_id].proofsList = new bytes32[](0x0);

    //pots[model_id] = new bytes32[](0x0);

    // nominate verifiers for this channel
    address[] memory v_addr = getEligibleProposer(k);
    for(uint i=0; i<v_addr.length; i++) {
        channelVerifiers[channel_id].push(v_addr[i]);
        registrantBusy[v_addr[i]] = true;   // this verifier is busy
    }

    InitChannel(channel_id);
    return true;
    }

  function getChannel(bytes32 channel_id) public view returns(bytes32, uint) {
      require(isChannel(channel_id));
      return (channelStructs[channel_id].model_id, channelStructs[channel_id].k);
    }

  function getVerifiers(bytes32 channel_id) public constant returns (address[]) {
    require(isChannel(channel_id));
    return channelVerifiers[channel_id];
    }

  function getNumberOfChannels() public constant returns (uint count) {
    return channelList.length;
    }

  function deposit() payable public returns (bool) {
	  // check max number of verifiers (refund if fails)
	  require(registrants.length < VERIFIER_QUOTA);
	  uint pos = registrantIndex[msg.sender];

	  // if validator exists, add stake and activate if enough stake
	  if (pos > 0) {
		  registrants[pos].stake += msg.value;
		  registrants[pos].active = registrants[pos].stake >= MIN_STAKE;
	  }
	  // if new validator
	  else if (pos == 0) {
		  pos = registrants.length++;
		  bool active = msg.value >= MIN_STAKE;
		  // Create new registrant passing address, data, stake, active
		  registrants[pos] = Registrant(msg.sender, msg.value, active);
		  // Update position in mapping
		  registrantIndex[msg.sender] = pos;
	   }
	  // Notify blockchain
	  emit Created(msg.sender, msg.value);
	  return true;
    }

  // TBI
  function withdraw() payable public returns (bool) {
    require(!registrantBusy[msg.sender]);

    // TODO make a payment from contract to sender

    // TODO remove sender from list of verifiers

	  emit Withdrawn(msg.sender);
	  return true;
    }

    /**
    * Set new registrar address, only registrar allowed
    * public_function
    * @param _registrar - The new registrar address.
    */

  function setNextRegistrar(address _registrar) public isRegistrar noEther returns (bool) {
      registrar = _registrar;
      return true;
    }

  /**
    * Get if a registrant is active or not
    * constant_function
    * @param _registrant - The registrant address.
    */
  function isActiveRegistrant(address _registrant)  public constant returns (bool) {
      // take index of this _registrant
      uint pos = registrantIndex[_registrant];
      return (pos > 0 && registrants[pos].active);
    }



	 /*
    * Set registrant active or not active, only registrar allowed
    * public_function
    * @param _id - The identity to change.
    * @param _isValid - The new validity of the thing.
    */

  function setRegistrantActive(address _registrant, bool is_active) public isRegistrar noEther returns(bool) {
        uint index = registrantIndex[_registrant];
	      // not found
        if (index == 0) {
            emit Error(2);
            return false;
        }

	    // not authorized
        if (registrar != msg.sender) {
            emit Error(3);
            return false;
        }
        // set valid field
        registrants[index].active = is_active;

        // Broadcast event
		    emit Updated(_registrant, registrar, is_active);
        return true;
    }


    /**
    * Get all the active registrants' addresses
	  * constant_function
    */

  function getRegistrants() public constant returns (address[]) {
        address[] memory result = new address[](registrants.length-1);
        for (uint j = 1; j < registrants.length; j++) {
			       if(registrants[j].active == true) {
				           result[j-1] = registrants[j].addr;
			              }
        }
        return result;
    }

	function getStake(address _registrant) public constant returns (uint) {
		  uint index = registrantIndex[_registrant];
		  require(index > 0);
		  return registrants[index].stake;
	   }


	  /**
    * Returns number of active registrants in the registrar
    */

  function getNumberRegistrants() public constant returns (uint) {
		    uint total = 0;
		    for(uint j=1;j<registrants.length;j++){
			     if(registrants[j].active == true) {
			          total++;
			            }
		    }
      return total;
    }

    /**
    * Function to reject value sends to the contract.
    * fallback_function
    */

  function () noEther public  {}

    /**
    * Destruct the smart contract. Since this is first, alpha release of Open Registry for IoT, updated versions will follow.
    * Registry's discontinue must be executed first.
    */
  function discontinue() public isRegistrar noEther {
      selfdestruct(msg.sender);
    }

  function getBalance() public constant returns (uint){
        return address(this).balance;
      }


    /* check if pool contains element */
    // FIXME convert this to a mapping (much more efficient)

  function contains(uint[] pool, uint element) pure returns(bool) {
        for(uint i=0; i<pool.length; i++){
            if(element == pool[i]){
                return true;
            }
        }
        return false;
      }

  function getEligibleProposer(uint num_verifiers) public constant returns (address[]) {
        uint num_registrants = getNumberRegistrants();  // get number of active registrants
        // FIXME require(num_registrants/num_verifiers > 2.5)

        // selecting as many verifiers as available registrants
        if (num_verifiers >= num_registrants) {
          return getRegistrants();
        }

        uint[] memory selected = new uint[](num_verifiers);  // array of the indexes of selected verifiers
        address[] memory v_addr = getRegistrants();  // addresses of active registrants

        // get block.hash
        uint blockNumber = block.number;
        uint block_hash = uint(keccak256(block.blockhash(blockNumber), block.timestamp));
        bytes32 hash = bytes32(block_hash);
        uint added = 0;  // number of unique verifiers added so far
        uint round = 0;  // selection round (keep selecting without duplicates)

        while(added < num_verifiers) {
            uint idx;
            uint product = 1;
            // calculate some random number from some digits in block hash
            for(uint i=round; i<round+2; i++){
                product = product*uint(hash[i]);
            }
            idx = product % num_registrants;

            // FIXME convert to a mapping (uint => bool)
            if(!contains(selected, idx))
            {
                selected[added] = idx;
                added++;
            }
            round++;
        }
        address[] memory selected_addr = new address[](num_verifiers);
        for(i=0; i<num_verifiers; i++){
          selected_addr[i] = v_addr[selected[i]];
          }
        return selected_addr;
        }
      }

pragma solidity ^0.4.25;

import "./FitchainLib.sol";

/**
@title Fitchain Validator Pool Contract
@author Fitchain Team
**/

contract VPC {

    uint256 MIN_STAKE         = 12000000000000000000;   // min stake in wei (12 eth)
    uint256 VERIFIER_QUOTA    = 1000;
    uint256 MIN_NUM_VERIFIERS = 1;  // FIXME change_me
    address public registrar;                        // address of account who inits

    // using Dictionary for Dictionary.Data;

    event Created(address registrant, uint stake);
    event Updated(address indexed registrant, address registrar, bool active);
    event Withdrawn(address addr);
    event InitChannel(bytes32 channelId);

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
        bool active;            // channel state
        uint k;                 // proofs in this channel require k sigs
        bytes32 channelId;      // assigned by contract
        bytes32 modelId;        // model to be verified in this channel
        address[] verifiers;    // verifiers addresses
    }

    mapping(bytes32 => Channel) public channels;
    bytes32[] public channelList;

    // Data structure containing the single proof for a model
    struct Proof {
        bool state;         // ssubmitted
        bool verified;      // verified
        bytes32[] merkelRoots; // Merkle-root of the training logs
        bytes32[] sigs;     // list of signatures provided by verifiers
    }

    mapping(bytes32 => Proof) pots;

    modifier noEther() {
        require(msg.value > 0, 'invalid ether amount!');
        _;
    }

    modifier isRegistrar() {
        require(msg.sender == registrar, 'Permission denied');
        _;
    }

    modifier isValidInitChannelReq(bytes32 channelId, uint256 k) {
        require(k > MIN_NUM_VERIFIERS, 'Invalid minimum number of verifiers');
        _;
    }

    modifier isChannel(bytes32 channelId) {
        require (channels[channelId].active, 'Channel Id already exists');
        _;
    }

    modifier isVerifier(bytes32 channelId) {
        bool exist = false;
        for (uint i=0; i < channels[channelId].verifiers.length; i++){
            if(msg.sender == channels[channelId].verifiers[i]) exist = true;
        }
        require(exist, 'sender not a verifier');
        _;
    }


    //   /**
    //   * Construct registry with and starting registrants lenght of one,
    //   * and registrar as msg.sender
    //   */
    constructor() public{
        registrar = msg.sender;
        registrants.length++;
    }
    // submit_proof(service_id, model_id, merkleroot, tx_eot, sig, sender_addr)
    // bytes32, bytes32, string, string, bytes, address
    // submit proof of training to model

    function submitProof(bytes32 serviceId, bytes32 modelId, string merkleroot, string eot,  bytes sig, address sender)
    public isChannel(modelId) returns (bool) {
        // Proof memory prf;
        // prf.sender = msg.sender;
        // prf.merkle_root = merkleroot;
        // prf.sigs = sig;
        // FIXME
        // proof key = hash(sender + model_id + merkle_root)
        // sender + merkle_root should be enough because we store it to potStructs[model_id]
        // there we go with the pot hash :)

        // bytes memory pot_hash = fitchainLib.concatenate3(bytes32(msg.sender), model_id, merkle_root);
        // bytes32 prf_key = keccak256(pot_hash);

        // // check if this proof has been submitted already
        // bool prf_exist = potStructs[model_id].proofsSubmitted[prf_key];
        // if(prf_exist == true){
        //     emit Error(6);
        //     return false;
        // }
        // potStructs[model_id].proofsList.push(prf_key);
        // potStructs[model_id].proofStructs[prf_key] = prf;
        // potStructs[model_id].proofsSubmitted[prf_key] = true;
        // // update merkle counter for this pot
        // uint count = potStructs[model_id].merkle_counters[merkle_root];
        // potStructs[model_id].merkle_counters[merkle_root] = count+1;
        // // TODO
        // // check number of current submissions
        // // call isPotValid() (rename to isPotGood? :)
        return true;
    }

    // given model_id returns the number of submitted proofs
    // function getProofCount(bytes32 channelId) public constant returns(uint) {
    //     return pots[channelId].proofsList.length;
    // }

    // given the model_id return the list of proof keys
    // function getProofsList(bytes32 channelId) public isChannel(channelId) view returns(bytes32[]) {
    //     return pots[channelId].proofsList;
    // }

    // !!WORK IN PROGRESS!! given model_id returns bool if model is verified by consensus (valid Pot)


    function isPotValid(bytes32 channelId) public isVerifier(channelId) view returns(bool) {
        for(uint i=0; i< channels[channelId].verifiers.length; i++){
            // count how many verifiers proposed this merkle root
            if(pots[channelId].verified) {
                return true;
            }
        }
        return false;
    }

    // function getValidationInfo(bytes32 channelId, bytes32 merkleRoot) public view returns(uint) {
    //     return pots[channels[channelId].proof].merkleRoots.length;
    // }


    function initChannel(bytes32 channelId, uint256 k) public
    isChannel(channelId) isValidInitChannelReq(channelId, k) returns (bool success) {
        channelList.push(channelId);
        pots[channelId] = Proof(false, false, new bytes32[](0), new bytes32[](0));
        channels[channelId] = Channel(true, k, channelId, channelId, new address[](0));
        // nominate verifiers for this channel
        address[] memory verifiersAddrs = getEligibleProposer(k);
        for(uint256 i=0; i< verifiersAddrs.length; i++) {
            channels[channelId].verifiers.push(verifiersAddrs[i]);
            registrantBusy[verifiersAddrs[i]] = true;   // this verifier is busy
        }
        emit InitChannel(channelId);
        return true;
    }

    function getChannel(bytes32 channelId) public isChannel(channelId) view returns(bytes32, uint) {
        return (channels[channelId].modelId, channels[channelId].k);
    }

    function getVerifiers(bytes32 channelId) public isChannel(channelId) view returns (address[]) {
        return channels[channelId].verifiers;
    }

    function getNumberOfChannels() public view returns (uint count) {
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

    /*
     * Set new registrar address, only registrar allowed
     * public_function
     * @param _registrar - The new registrar address.
    */
    function setNextRegistrar(address _registrar) public isRegistrar noEther returns (bool) {
        registrar = _registrar;
        return true;
    }

    /*
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

    /*
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

    /*
     * Function to reject value sends to the contract.
     * fallback_function
     */
    function () noEther public  {}

    /*
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
        uint256[] memory selected = new uint[](num_verifiers);  // array of the indexes of selected verifiers
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
            if(!contains(selected, idx)) {
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
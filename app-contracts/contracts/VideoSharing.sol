pragma solidity ^0.6.12;
struct Video {
    bytes path; // ipfs path
    bytes20 title; // title of the file
}

contract VideoSharingContract {
    // ERC20 standards
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // triggered when we upload video information
    event UploadVideo(address indexed user, uint256 index); 
    
    // triggered when we like a video
    event LikeVideo(address indexed video_liker, address indexed video_uploader, uint256 value);
    
    // tracker of how many videos user has uploaded
    mapping(address => uint256) public user_videos_index;
    
    // ERC20 standars
    bytes20 public name;
    bytes3 public symbol;
    uint256 public totalSupply;
    uint256 public decimals;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    
    // keep all videos from users
    mapping(address => mapping(uint256 => Video)) public all_videos;
    
    // whether certain user liked the video
    mapping(bytes => bool) public likes_videos;
    
    // how many likes this video has already
    mapping(bytes => uint256) public aggregate_likes;
    
    constructor() public {
        uint256 _initialSupply = 500;
        uint256 _decimals = 3;
        
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** _decimals;
        balances[msg.sender] = totalSupply;
        name = "Video Sharing Coin";
        symbol = "VID";
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) public returns(bool) {
        return _transfer(msg.sender, _to, _amount);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_value <= allowed[_from][msg.sender]);
        require(_value <= balances[_from]);
        
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns(bool) {
        allowed[msg.sender][_spender] = _amount;
        
        emit Approval(msg.sender, _spender, _amount);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }
    
    function uploadVideo(bytes memory _video_path, bytes20 _video_title) public returns(bool) {
        uint256 _index = user_videos_index[msg.sender];
        
        all_videos[msg.sender][_index] = Video({ path: _video_path, title: _video_title });
        user_videos_index[msg.sender] += 1;
        
        emit UploadVideo(msg.sender, _index);
        
        return true;
    }
    
    function latestVideosIndex(address _user) public view returns(uint256) {
        return user_videos_index[_user];
    }
    
    function videosPath(address _user, uint256 _index) public view returns(bytes memory) {
        return all_videos[_user][_index].path;
    }
    
    function videosTitle(address _user, uint256 _index) public view returns(bytes20) {
        return all_videos[_user][_index].title;
    }
    
    function likeVideo(address _user, uint256 _index) public payable returns(bool) {
        
        bytes32 _msg_sender_str = _toBytes(msg.sender);
        bytes32 _user_str = _toBytes(_user);
        bytes32 _index_str = bytes32(_index);
        
        bytes memory _key = _concat(_toBytes(_msg_sender_str),_concat(_toBytes(_user_str), _toBytes(_index_str)));
        bytes memory _likes_key = _concat(_toBytes(_user_str), _toBytes(_index_str));
        
        require(_index < user_videos_index[_user]);
        require(likes_videos[_key] == false);
        
        likes_videos[_key] = true;
        aggregate_likes[_likes_key] += 1;
        _transfer(msg.sender, _user, 1);
        
        emit LikeVideo(msg.sender, _user, _index);
        
        return true;
    }
    
    function videoHasBeenLiked(address _user_like, address _user_video, uint256, uint256 _index) public view returns(bool) {
        bytes32 _user_like_str = _toBytes(_user_like);
        bytes32 _user_video_str = _toBytes(_user_video);
        bytes32 _index_str = bytes32(_index);
        
        bytes memory _key = _concat(_toBytes(_user_like_str), _concat(_toBytes(_user_video_str), _toBytes(_index_str)));
        
        return likes_videos[_key];
    }
    
    function videoAggregateLikes(address _user_video, uint256, uint256 _index) public view returns(uint256) {
        bytes32 _user_video_str = _toBytes(_user_video);
        bytes32 _index_str = bytes32(_index);
        
        bytes memory _key = _concat(_toBytes(_user_video_str), _toBytes(_index_str));
        
        return aggregate_likes[_key];
    }
    
    function _transfer(address _source, address _to, uint256 _amount) private returns(bool) {
        require(balances[_source] >= _amount);
        balances[_source] -= _amount;
        balances[_to] += _amount;
        
        emit Transfer(_source, _to, _amount);
        
        return true;
    }
    
    function _toBytes(address a) private pure returns (bytes32 b){
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
       }
    }
    
    function _toBytes(bytes32 _data) private pure returns (bytes memory) {
        return abi.encodePacked(_data);
    }
    
    function _concat(bytes memory a, bytes memory b) public pure returns (bytes memory c) {
        uint alen = a.length;
        uint totallen = alen + b.length;
        
        // Count the loops required for array a (sets of 32 bytes)
        uint loopsa = (a.length + 31) / 32;
        // Count the loops required for array b (sets of 32 bytes)
        uint loopsb = (b.length + 31) / 32;
        
        assembly {
            let m := mload(0x40)
            // Load the length of both arrays to the head of the new bytes array
            mstore(m, totallen)
            // Add the contents of a to the array
            for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
            // Add the contents of b to the array
            for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }
}
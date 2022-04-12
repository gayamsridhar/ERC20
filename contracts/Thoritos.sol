//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;
// -----------------------------------------
// ERC-20 Token Standard
// -----------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface EIP1132Interface {
    function lock(bytes32 _reason, uint256 _amount, uint256 _time) external returns (bool);
    function tokensLocked(address _of, bytes32 _reason) external view returns (uint256 amount);
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time) external view returns (uint256 amount);
    function totalBalanceOf(address _of)  external view returns (uint256 amount);
    function extendLock(bytes32 _reason, uint256 _time)  external returns (bool);
    function increaseLockAmount(bytes32 _reason, uint256 _amount) external returns (bool);
    function tokensUnlockable(address _of, bytes32 _reason) external view returns (uint256 amount);
    function getUnlockableTokens(address _of) external view returns (uint256 unlockableTokens);
    function unlock(address _of) external returns (uint256 unlockableTokens);
    event Locked(address indexed _of, uint256 indexed _reason, uint256 _amount, uint256 _validity);
    event Unlocked(address indexed _of, uint256 indexed _reason, uint256 _amount);
}


// The Cryptos Token Contract
contract Thoritos is ERC20Interface{
    string public name = "Thoritos";
    string public symbol = "THOR";
    uint public decimals = 8;
    uint public override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;

    event Mint(address indexedto, uint tokens); 
    event Burn(address indexedto, uint tokens); 
    event Locked(address indexed _of, bytes32 indexed _reason, uint256 _amount, uint256 _validity);
    event Unlocked(address indexed _of, bytes32 indexed _reason, uint256 _amount);

    string internal constant ALREADY_LOCKED = "Tokens already locked";
    string internal constant NOT_LOCKED = "No tokens locked";
    string internal constant AMOUNT_ZERO = "Amount can not be 0";


    mapping(address => bytes32[]) public lockReason;
    struct lockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }
    mapping(address => mapping(bytes32 => lockToken)) public locked;

    
    
    constructor(){
        founder = msg.sender;
    }    

    modifier onlyFounder() {
        require(founder == msg.sender, "not owner");
        _;
    }
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }    
    
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender] >= tokens, "not enoguh tokens");
        require(to != address(0), "transfer to the zero address");
        balances[msg.sender] -= tokens;        
        balances[to] += tokens;
        
        emit Transfer(msg.sender, to, tokens);        
        return true;
    }    
    
    function allowance(address tokenOwner, address spender) public view override returns(uint){
        return allowed[tokenOwner][spender];
    }    
    
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens, "not enoguh tokens");
        require(spender != msg.sender , "spender should not be the owner");
        require(tokens > 0, "token count must freater than zero");
        require(spender != address(0), "approve to the zero address");
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }    
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
         require(allowed[from][to] >= tokens, "not enoguh tokens for allowance");
         require(balances[from] >= tokens, "not enoguh tokens");
         require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");

         allowed[from][to] -= tokens;
         balances[from] -= tokens;
         balances[to] += tokens;         
         
         return true;
     }

    function mint(address to, uint tokens) public onlyFounder returns(bool success){        
        require(to != address(0), "mint to the zero address"); 
        require(totalSupply+tokens <= 100000, "exceeded the total supply limit");

        totalSupply += tokens;          
        balances[to] += tokens;        
        
        emit Mint(to, tokens);        
        return true;
    } 

    function burn(address to, uint tokens) public onlyFounder returns(bool success){
        require(balances[to] >= tokens, "burn amount exceeds balance");
        require(to != address(0), "burn to the zero address");
        
        balances[to] -= tokens;
        totalSupply -= tokens;
        
        emit Burn(to, tokens);        
        return true;
    }

    
    function tokensLocked(address _of, bytes32 _reason) public view returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }

    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time) public view returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time)
            amount = locked[_of][_reason].amount;
    }

    function totalBalanceOf(address _of) public view returns (uint256 amount)
    {
        amount = balanceOf(_of);

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount += tokensLocked(_of, lockReason[_of][i]);
        }   
    }

    function lock(bytes32 _reason, uint256 _amount, uint256 _time) public returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);
        uint256 validUntil = block.timestamp + _time; 
        if (locked[msg.sender][_reason].amount == 0)
            lockReason[msg.sender].push(_reason);

        transfer(address(this), _amount);

        locked[msg.sender][_reason] = lockToken(_amount, validUntil, false);

        emit Locked(msg.sender, _reason, _amount, validUntil);
        return true;
    }

    function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time) public returns (bool)
    {
        uint256 validUntil = block.timestamp + _time;
        require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_to][_reason].amount == 0)
            lockReason[_to].push(_reason);

        transfer(address(this), _amount);

        locked[_to][_reason] = lockToken(_amount, validUntil, false);
        
        emit Locked(_to, _reason, _amount, validUntil);
        return true;
    }

    function extendLock(bytes32 _reason, uint256 _time) public returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

        locked[msg.sender][_reason].validity = locked[msg.sender][_reason].validity + _time;

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }

    function increaseLockAmount(bytes32 _reason, uint256 _amount) public returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
        transfer(address(this), _amount);

        locked[msg.sender][_reason].amount += _amount;

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }

    function tokensUnlockable(address _of, bytes32 _reason) public view returns (uint256 amount)
    {
        if (locked[_of][_reason].validity >= block.timestamp && !locked[_of][_reason].claimed)
                   amount = locked[_of][_reason].amount;
    }

    function unlock(address _of) public returns (uint256 unlockableTokens)
    {
        uint256 lockedTokens;

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
            if (lockedTokens > 0) {
                unlockableTokens += lockedTokens;
                locked[_of][lockReason[_of][i]].claimed = true;
                emit Unlocked(_of, lockReason[_of][i], lockedTokens);
            }
        } 

        if (unlockableTokens > 0)
            this.transfer(_of, unlockableTokens);
    }

    function getUnlockableTokens(address _of) public view returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens += tokensUnlockable(_of, lockReason[_of][i]);
        }          
    }

    function currentTimeStamp() view public returns (uint256 currentTime)
    {
        currentTime = block.timestamp;
    }

    function validUntilOf(address _of, bytes32 _reason ) view public returns (uint256 time)
    {
        time = locked[_of][_reason].validity;
    }


}

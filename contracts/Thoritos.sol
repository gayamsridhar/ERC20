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

    
    
    constructor(){
        founder = msg.sender;
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

    modifier onlyFounder() {
        require(founder == msg.sender, "not owner");
        _;
    }
}

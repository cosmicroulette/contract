// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external payable;

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata
    ) external payable;
}


contract DigitizedPlanetONE is IERC721 {
    address payable private patron = 0xe56541D233Dc87D23215292D8FC4994ef622bd07;
    string public blockchain = "Harmony One";

    string private _name;
    string private _symbol;
    Planet[] public planets;
    uint256 private pendingPlanetCount;
    mapping(uint256 => address) private _tokenOwner;
    mapping(address => uint256) private _ownedTokensCount;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => PlanetTxn[]) private planetTxns;
    uint256 public index;
    struct Planet {
        uint256 id;
        string title;
        string description;
        uint256 price;
        string date;
        string authorName;
        address payable author;
        address payable owner;
        uint256 status;
        string image;
    }
    struct PlanetTxn {
        uint256 id;
        uint256 price;
        address seller;
        address buyer;
        uint256 txnDate;
        uint256 status;
    }
    //d
    event LogPlanetSold(
        uint256 _tokenId,
        string _title,
        string _authorName,
        uint256 _price,
        address _author,
        address _current_owner,
        address _buyer
    );
    event LogPlanetTokenCreate(
        uint256 _tokenId,
        string _title,
        string _category,
        string _authorName,
        uint256 _price,
        address _author,
        address _current_owner
    );
    event LogPlanetResell(uint256 _tokenId, uint256 _status, uint256 _price);

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function createTokenAndSellPlanet(
        string memory _title,
        string memory _description,
        string memory _date,
        string memory _authorName,
        uint256 _price,
        string memory _image
    ) public payable {
        require(bytes(_title).length > 0, "The title cannot be empty");
        require(bytes(_date).length > 0, "The Date cannot be empty");
        require(
            bytes(_description).length > 0,
            "The description cannot be empty"
        );
        require(_price > 0, "The price cannot be empty");
        require(bytes(_image).length > 0, "The image cannot be empty");
        // add require id <10000
        require(index <10000);
        // add require transfer = 200 one
        require(msg.value == 200 ether);
        // add transfer amount to patron
        patron.transfer(msg.value);

        Planet memory _planet = Planet({
            id: index,
            title: _title,
            description: _description,
            price: _price,
            date: _date,
            authorName: _authorName,
            author: msg.sender,
            owner: msg.sender,
            status: 1,
            image: _image
        });
        planets.push(_planet);
        uint256 tokenId = planets.length - 1;
        _mint(msg.sender, tokenId);
        emit LogPlanetTokenCreate(
            tokenId,
            _title,
            _date,
            _authorName,
            _price,
            msg.sender,
            msg.sender
        );
        index++;
        pendingPlanetCount++;
    }

    function buyPlanet(uint256 _tokenId) public payable {
        (
            uint256 _id,
            string memory _title,
            ,
            uint256 _price,
            uint256 _status,
            ,
            string memory _authorName,
            address _author,
            address payable _current_owner,

        ) = findPlanet(_tokenId);
        require(_current_owner != address(0), "Cannot be zero address");
        require(msg.sender != address(0), "Cannot be zero address");
        require(msg.sender != _current_owner, "Cannot be current owner");
        require(msg.value >= _price, "Invalid Amount");
        require(planets[_tokenId].owner != address(0), "Cannot be zero address");

        //transfer ownership of planet
        _transfer(_current_owner, msg.sender, _tokenId);
        //return extra payment
        if (msg.value > _price) msg.sender.transfer(msg.value - _price);
        //make a payment
        _current_owner.transfer(_price);
        planets[_tokenId].owner = msg.sender;
        planets[_tokenId].status = 0;
        PlanetTxn memory _planetTxn = PlanetTxn({
            id: _id,
            price: _price,
            seller: _current_owner,
            buyer: msg.sender,
            txnDate: now,
            status: _status
        });
        planetTxns[_id].push(_planetTxn);
        pendingPlanetCount--;

        emit LogPlanetSold(
            _tokenId,
            _title,
            _authorName,
            _price,
            _author,
            _current_owner,
            msg.sender
        );
    }

    function resellPlanet(uint256 _tokenId, uint256 _price) public payable {
        require(msg.sender != address(0), "Cannot be zero address");
        require(isOwnerOf(_tokenId, msg.sender), "No one else");
        planets[_tokenId].status = 1;
        planets[_tokenId].price = _price;
        pendingPlanetCount++;
        emit LogPlanetResell(_tokenId, 1, _price);
    }

    function findPlanet(uint256 _tokenId)
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            uint256,
            uint256 status,
            string memory,
            string memory,
            address,
            address payable,
            string memory
        )
    {
        Planet memory planet = planets[_tokenId];
        return (
            planet.id,
            planet.title,
            planet.description,
            planet.price,
            planet.status,
            planet.date,
            planet.authorName,
            planet.author,
            planet.owner,
            planet.image
        );
    }

    function findAllPlanets()
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        uint256 arrLength = planets.length;
        uint256[] memory ids = new uint256[](arrLength);
        address[] memory authors = new address[](arrLength);
        address[] memory owners = new address[](arrLength);
        uint256[] memory status = new uint256[](arrLength);
        for (uint256 i = 0; i < arrLength; ++i) {
            Planet memory planet = planets[i];
            ids[i] = planet.id;
            authors[i] = planet.author;
            owners[i] = planet.owner;
            status[i] = planet.status;
        }
        return (ids, authors, owners, status);
    }

    function findAllPendingPlanets()
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        if (pendingPlanetCount == 0) {
            return (
                new uint256[](0),
                new address[](0),
                new address[](0),
                new uint256[](0)
            );
        } else {
            uint256 arrLength = planets.length;
            uint256[] memory ids = new uint256[](pendingPlanetCount);
            address[] memory authors = new address[](pendingPlanetCount);
            address[] memory owners = new address[](pendingPlanetCount);
            uint256[] memory status = new uint256[](pendingPlanetCount);
            uint256 idx = 0;
            for (uint256 i = 0; i < arrLength; ++i) {
                Planet memory planet = planets[i];
                if (planet.status == 1) {
                    ids[idx] = planet.id;
                    authors[idx] = planet.author;
                    owners[idx] = planet.owner;
                    status[idx] = planet.status;
                    idx++;
                }
            }
            return (ids, authors, owners, status);
        }
    }

    function findMyPlanets() public view returns (uint256[] memory _myPlanets) {
        require(msg.sender != address(0), "Cannot be zero address");
        uint256 numOftokens = balanceOf(msg.sender);
        if (numOftokens == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory myPlanets = new uint256[](numOftokens);
            uint256 idx = 0;
            uint256 arrLength = planets.length;
            for (uint256 i = 0; i < arrLength; i++) {
                if (_tokenOwner[i] == msg.sender) {
                    myPlanets[idx] = i;
                    idx++;
                }
            }
            return myPlanets;
        }
    }

    function getPlanetAllTxn(uint256 _tokenId)
        public
        view
        returns (
            uint256[] memory _id,
            uint256[] memory _price,
            address[] memory seller,
            address[] memory buyer,
            uint256[] memory _txnDate
        )
    {
        PlanetTxn[] memory planetTxnList = planetTxns[_tokenId];
        uint256 arrLength = planetTxnList.length;
        uint256[] memory ids = new uint256[](arrLength);
        uint256[] memory prices = new uint256[](arrLength);
        address[] memory sellers = new address[](arrLength);
        address[] memory buyers = new address[](arrLength);
        uint256[] memory txnDates = new uint256[](arrLength);
        for (uint256 i = 0; i < planetTxnList.length; ++i) {
            PlanetTxn memory planetTxn = planetTxnList[i];
            ids[i] = planetTxn.id;
            prices[i] = planetTxn.price;
            sellers[i] = planetTxn.seller;
            buyers[i] = planetTxn.buyer;
            txnDates[i] = planetTxn.txnDate;
        }
        return (ids, prices, sellers, buyers, txnDates);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        _ownedTokensCount[_to]++;
        _ownedTokensCount[_from]--;
        _tokenOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function _mint(address _to, uint256 tokenId) internal {
        require(_to != address(0), "Cannot be zero address");
        require(!_exists(tokenId), "");
        _tokenOwner[tokenId] = _to;
        _ownedTokensCount[_to]++;
        emit Transfer(address(0), _to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function balanceOf(address _owner) public override view returns (uint256) {
        return _ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId)
        public
        override
        view
        returns (address _owner)
    {
        _owner = _tokenOwner[_tokenId];
    }

    function approve(address _to, uint256 _tokenId) public override payable {
        require(isOwnerOf(_tokenId, msg.sender), "No one else");
        _tokenApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override payable {
        require(_to != address(0), "Cannot be zero address");
        require(isOwnerOf(_tokenId, _from), "Invalid owner");
        require(isApproved(_to, _tokenId), "Wrong approval");
        _transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(_to != address(0), "Cannot be zero address");
        require(isOwnerOf(_tokenId, msg.sender), "No one else");
        _transfer(msg.sender, _to, _tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        override
        view
        returns (address)
    {
        require(_exists(tokenId), "Does not exist");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved)
        public
        override
    {
        require(operator != msg.sender, "Operator should be current owner");
        _operatorApprovals[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        override
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override payable {
        // NOT IMPLEMENTED
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override payable {
        // NOT IMPLEMENTED
    }

    function isOwnerOf(uint256 tokenId, address account)
        public
        view
        returns (bool)
    {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "Cannot be zero address");
        return owner == account;
    }

    function isApproved(address _to, uint256 _tokenId)
        private
        view
        returns (bool)
    {
        return _tokenApprovals[_tokenId] == _to;
    }
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract Link {
    struct Transaction {
        address buyer;
        address seller;
        string link;
        uint256 timestamp;
    }

    mapping(address => string[]) public userLinks; // Mapping of address => links
    mapping(string => address) public linkToAddress; // Mapping of link => address
    address[] public allUsers; // Storing all the users' addresses to get all the data
    mapping(string => address[]) public previousOwnersMap; // Mapping to store the previous owners for each link


    // Event to log link bought
    event LinkBought(
        address indexed buyer,
        address indexed seller,
        string link,
        uint256 timestamp
    );

    Transaction[] public transactions;

    // Store the link in the array for the specified user
    function storeLink(string memory _link) public {
        userLinks[msg.sender].push(_link);
        // Update the linkToAddress mapping with the seller's address
        linkToAddress[_link] = msg.sender;

        // If the user is not already in the allUsers array, add them
        if (userLinks[msg.sender].length == 1) {
            allUsers.push(msg.sender);
        }
    }

    // Deleting the links from the array
    function deleteLink(string memory _link) public {
        uint256 indexToDelete = findLinkIndex(msg.sender, _link);
        require(indexToDelete < userLinks[msg.sender].length, "Link not found");

        // Swap the link with the last element in the array
        uint256 lastIndex = userLinks[msg.sender].length - 1;
        if (indexToDelete != lastIndex) {
            userLinks[msg.sender][indexToDelete] = userLinks[msg.sender][
                lastIndex
            ];
        }

        // Delete the last element (previously the link to delete)
        userLinks[msg.sender].pop();
    }

    // Helper function for deleting element from array
    function findLinkIndex(
        address _user,
        string memory _link
    ) internal view returns (uint256) {
        uint256 linkCount = userLinks[_user].length;
        for (uint256 i = 0; i < linkCount; i++) {
            if (
                keccak256(bytes(userLinks[_user][i])) == keccak256(bytes(_link))
            ) {
                return i;
            }
        }
        return linkCount;
    }

    // Get all the links of the user
    function getPersonalLinks() public view returns (string[] memory) {
        return userLinks[msg.sender];
    }

    // Get all the links to use at the marketplace: Showing all the posts at once
    function getAllLinks() public view returns (string[] memory) {
        uint256 totalLinks = 0; // Count of links
        // Counting totalLinks for usage
        for (uint256 i = 0; i < allUsers.length; i++) {
            totalLinks += userLinks[allUsers[i]].length;
        }

        // Using all Links
        string[] memory allLinks = new string[](totalLinks);
        uint256 currentIndex = 0;

        // Adding the links in allLinks
        for (uint256 i = 0; i < allUsers.length; i++) {
            for (uint256 j = 0; j < userLinks[allUsers[i]].length; j++) {
                allLinks[currentIndex] = userLinks[allUsers[i]][j];
                currentIndex++;
            }
        }
        return allLinks;
    }



    function buyLink(string memory _link) public payable {
        address _seller = linkToAddress[_link];
        require(_seller != address(0), "Link not found");
        require(msg.sender != _seller, "Cannot buy your own link");

        // Ensure the link exists and is owned by the seller
        uint256 linkIndex = findLinkIndex(_seller, _link);
        require(linkIndex < userLinks[_seller].length, "Link not found");

        // Get the link price from the seller
        uint256 linkPrice = 2 ether; // Set the link price here (2 ether as an example)
        require(msg.value >= linkPrice, "Insufficient funds");

        // Update the previous owners list for the link
        // Now we can check for if the owners are more
        previousOwnersMap[_link].push(_seller);

        // Distribute Ether to previous owners
        // Calcualting no of owners 
        address[] memory previousOwners = previousOwnersMap[_link];
        uint256 numberOwner = previousOwners.length;

        // If the owners are 2 or more than 2 then we split
        if (numberOwner >= 2) {
            // Calculate the distribution amount (25% of the link price)
            uint256 distributionAmount = (linkPrice * 50) / 100;

            // Calculate the amount to be sent to the seller (90% of the link price)
            uint256 amountToSeller = linkPrice - distributionAmount;

            // Transfer the Ether to the seller
            payable(_seller).transfer(amountToSeller);

            // Share for each owner
            uint256 sharePerOwner = distributionAmount / numberOwner;
            for (uint256 i = 0; i < previousOwners.length; i++) {
                payable(previousOwners[i]).transfer(sharePerOwner);
            }

        }else{
            payable(_seller).transfer(linkPrice);
        }
        
        // Remove the link from the seller's array
        uint256 lastIndex = userLinks[_seller].length - 1;
        if (linkIndex != lastIndex) {
            userLinks[_seller][linkIndex] = userLinks[_seller][lastIndex];
        }
        userLinks[_seller].pop();

        // Add the link to the buyer's array
        userLinks[msg.sender].push(_link);

        // If the buyer is not already in the allUsers array, add them
        if (userLinks[msg.sender].length == 1) {
            allUsers.push(msg.sender);
        }

        // Update the linkToAddress mapping with the buyer's address
        linkToAddress[_link] = msg.sender;

        // Store the transaction details
        Transaction memory newTransaction = Transaction({
            buyer: msg.sender,
            seller: _seller,
            link: _link,
            timestamp: block.timestamp
        });
        transactions.push(newTransaction);

        // Emit an event to log the transaction
        emit LinkBought(msg.sender, _seller, _link, block.timestamp);
    }

    // Get the previous owners of a link
    function getPreviousOwners(string memory _link) public view returns (address[] memory) {
        return previousOwnersMap[_link];
    }

    // Get all transactions of a specific user
    function getUserTransactions() public view returns (Transaction[] memory) {
        uint256 userTransactionCount = 0;
        // Count the user's transactions
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].buyer == msg.sender) {
                userTransactionCount++;
            }
        }

        // Create an array to hold the user's transactions
        Transaction[] memory userTransactions = new Transaction[](
            userTransactionCount
        );
        uint256 currentIndex = 0;

        // Populate the user's transactions array
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].buyer == msg.sender) {
                userTransactions[currentIndex] = Transaction({
                    buyer: transactions[i].buyer,
                    seller: transactions[i].seller,
                    link: transactions[i].link,
                    timestamp: uint256(transactions[i].timestamp) // Explicit conversion here
                });
                currentIndex++;
            }
        }
        return userTransactions;
    }
}
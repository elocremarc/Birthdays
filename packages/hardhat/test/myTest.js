const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

beforeEach(async function () {
  [owner, alice, bob] = await ethers.getSigners();
});

describe("Perpetual Birthday Party!", function () {
  describe("Birthday Contract", function () {
    it("Should deploy contract", async function () {
      const Birthday = await ethers.getContractFactory("Birthday");

      birthday = await Birthday.deploy();
    });
    it("Should have proper owner", async function () {
      expect(await birthday.owner()).to.equal(owner.address);
    });
  });
});

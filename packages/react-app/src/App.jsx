/* eslint-disable react/jsx-no-target-blank */
import { LinkOutlined } from "@ant-design/icons";
import { StaticJsonRpcProvider, Web3Provider } from "@ethersproject/providers";
import { formatEther, parseEther } from "@ethersproject/units";
import WalletConnectProvider from "@walletconnect/web3-provider";
import { Alert, Button, Card, Col, Input, List, Menu, Row } from "antd";
import "antd/dist/antd.css";
import { useUserAddress } from "eth-hooks";
import { utils } from "ethers";
import React, { useCallback, useEffect, useState } from "react";
import ReactJson from "react-json-view";
import { BrowserRouter, Link, Route, Switch } from "react-router-dom";
import StackGrid from "react-stack-grid";
import Web3Modal from "web3modal";
import "./App.css";
//import assets from "./assets.js";
import { Account, Address, AddressInput, Contract, Faucet, GasGauge, Header, Ramp, ThemeSwitch } from "./components";
import { DAI_ABI, DAI_ADDRESS, INFURA_ID, NETWORK, NETWORKS } from "./constants";
import { Transactor } from "./helpers";
import {
  useBalance,
  useContractLoader,
  useContractReader,
  useEventListener,
  useExchangePrice,
  useExternalContractLoader,
  useGasPrice,
  useOnBlock,
  useUserProvider,
} from "./hooks";
import { BlockPicker } from "react-color";
import { ethers } from "ethers";
import styled, { keyframes } from "styled-components";
import { bounceIn, rubberBand, pulse } from "react-animations";
import { v4 as uuidv4 } from "uuid";

const { BufferList } = require("bl");
// https://www.npmjs.com/package/ipfs-http-client
const ipfsAPI = require("ipfs-http-client");

const ipfs = ipfsAPI({ host: "ipfs.infura.io", port: "5001", protocol: "https" });
const bounce = keyframes`${bounceIn}`;
const pulseAnimation = keyframes`${pulse}`;
const scale = keyframes`
  from {
    transform: scale(1);
  }

  to {
    transform: scale(1.1);
  }
`;

const ColorCard = styled.div`
  width: 100px;
  height: 100px;
  background-color: ${props => props.color};
  border-radius: 5px;
  transition: all 0.5s ease;

  &:hover {
    transform: scale(1.1);
    transition-duration: 0.5s;
  }
`;

const Bounce = styled.div`
  animation: 1.5s ${pulse};
`;

const NFTsvg = ({ bgColor, textColor }) => (
  <>
    <svg width="400" height="400">
      <rect width="400" height="400" fill={bgColor} />
      <text x="200" y="300" letter-spacing="3px" font-size="3em" text-anchor="middle" font-family="Impact" fill="black">
        ????
      </text>

      <text
        fill={textColor}
        x="200"
        y="210"
        letter-spacing="3px"
        font-size="4em"
        text-anchor="middle"
        font-family="Impact"
      >
        April
      </text>
      <text
        x="350"
        y="50"
        letter-spacing="2px"
        font-size="2em"
        text-anchor="middle"
        font-family="Impact"
        fill={textColor}
      >
        <tspan>20</tspan>
        <tspan font-size="0.6em" dy="-0.55em">
          th
        </tspan>
      </text>
    </svg>
  </>
);
//console.log("???? Assets: ", assets);

/*
    Welcome to ???? scaffold-eth !

    Code:
    https://github.com/austintgriffith/scaffold-eth

    Support:
    https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA
    or DM @austingriffith on twitter or telegram

    You should get your own Infura.io ID and put it in `constants.js`
    (this is your connection to the main Ethereum network for ENS etc.)


    ???? EXTERNAL CONTRACTS:
    You can also bring in contract artifacts in `constants.js`
    (and then use the `useExternalContractLoader()` hook!)
*/

/// ???? What chain are your contracts deployed to?
const targetNetwork = NETWORKS.rinkeby; // <------- select your target frontend network (localhost, rinkeby, xdai, mainnet)

// ???? Sorry for all the console logging
const DEBUG = true;

// helper function to "Get" from IPFS
// you usually go content.toString() after this...
const getFromIPFS = async hashToGet => {
  for await (const file of ipfs.get(hashToGet)) {
    console.log(file.path);
    if (!file.content) continue;
    const content = new BufferList();
    for await (const chunk of file.content) {
      content.append(chunk);
    }
    console.log(content);
    return content;
  }
};

// ???? providers
if (DEBUG) console.log("???? Connecting to Mainnet Ethereum");
// const mainnetProvider = getDefaultProvider("mainnet", { infura: INFURA_ID, etherscan: ETHERSCAN_KEY, quorum: 1 });
// const mainnetProvider = new InfuraProvider("mainnet",INFURA_ID);
//
// attempt to connect to our own scaffold eth rpc and if that fails fall back to infura...
// Using StaticJsonRpcProvider as the chainId won't change see https://github.com/ethers-io/ethers.js/issues/901
const scaffoldEthProvider = new StaticJsonRpcProvider("https://rpc.scaffoldeth.io:48544");
const mainnetInfura = new StaticJsonRpcProvider("https://mainnet.infura.io/v3/" + INFURA_ID);
// ( ?????? Getting "failed to meet quorum" errors? Check your INFURA_I

// ???? Your local provider is usually pointed at your local blockchain
const localProviderUrl = targetNetwork.rpcUrl;
// as you deploy to other networks you can set REACT_APP_PROVIDER=https://dai.poa.network in packages/react-app/.env
const localProviderUrlFromEnv = process.env.REACT_APP_PROVIDER ? process.env.REACT_APP_PROVIDER : localProviderUrl;
if (DEBUG) console.log("???? Connecting to provider:", localProviderUrlFromEnv);
const localProvider = new StaticJsonRpcProvider(localProviderUrlFromEnv);

// ???? block explorer URL
const blockExplorer = targetNetwork.blockExplorer;

/*
  Web3 modal helps us "connect" external wallets:
*/
const web3Modal = new Web3Modal({
  // network: "mainnet", // optional
  cacheProvider: true, // optional
  providerOptions: {
    walletconnect: {
      package: WalletConnectProvider, // required
      options: {
        infuraId: INFURA_ID,
      },
    },
  },
});

function App(props) {
  const mainnetProvider = scaffoldEthProvider && scaffoldEthProvider._network ? scaffoldEthProvider : mainnetInfura;

  const logoutOfWeb3Modal = async () => {
    await web3Modal.clearCachedProvider();
    if (injectedProvider && injectedProvider.provider && typeof injectedProvider.provider.disconnect == "function") {
      await injectedProvider.provider.disconnect();
    }
    setTimeout(() => {
      window.location.reload();
    }, 1);
  };

  const [injectedProvider, setInjectedProvider] = useState();
  /* ???? This hook will get the price of ETH from ???? Uniswap: */
  const price = useExchangePrice(targetNetwork, mainnetProvider);

  /* ???? This hook will get the price of Gas from ?????? EtherGasStation */
  const gasPrice = useGasPrice(targetNetwork, "fast");
  // Use your injected provider from ???? Metamask or if you don't have it then instantly generate a ???? burner wallet.
  const userProvider = useUserProvider(injectedProvider, localProvider);
  const address = useUserAddress(userProvider);

  // You can warn the user if you would like them to be on a specific network
  const localChainId = localProvider && localProvider._network && localProvider._network.chainId;
  const selectedChainId = userProvider && userProvider._network && userProvider._network.chainId;

  // For more hooks, check out ????eth-hooks at: https://www.npmjs.com/package/eth-hooks

  // The transactor wraps transactions and provides notificiations
  const tx = Transactor(userProvider, gasPrice);

  // Faucet Tx can be used to send funds from the faucet
  const faucetTx = Transactor(localProvider, gasPrice);

  // ???? scaffold-eth is full of handy hooks like this one to get your balance:
  const yourLocalBalance = useBalance(localProvider, address);

  // Just plug in different ???? providers to get your balance on different chains:
  const yourMainnetBalance = useBalance(mainnetProvider, address);

  // Load in your local ???? contract and read a value from it:
  const readContracts = useContractLoader(localProvider);

  // If you want to make ???? write transactions to your contracts, use the userProvider:
  const writeContracts = useContractLoader(userProvider);

  // EXTERNAL CONTRACT EXAMPLE:
  //
  // If you want to bring in the mainnet DAI contract it would look like:
  const isSigner = injectedProvider && injectedProvider.getSigner && injectedProvider.getSigner()._isSigner;

  // If you want to call a function on a new block
  useOnBlock(mainnetProvider, () => {
    console.log(`??? A new mainnet block is here: ${mainnetProvider._lastBlockNumber}`);
  });

  // Then read your DAI balance like:
  /*
  const myMainnetDAIBalance = useContractReader({ DAI: mainnetDAIContract }, "DAI", "balanceOf", [
    "0x34aA3F359A9D614239015126635CE7732c18fDF3",
  ]);*/

  // keep track of a variable from the contract in the local React state:
  const balance = useContractReader(readContracts, "Birthday", "balanceOf", [address]);
  console.log("???? balance:", balance);

  const balanceColors = useContractReader(readContracts, "Colors", "balanceOf", [address]);
  console.log("???? balance Colors:", balance);

  // ???? Listen for broadcast events
  const transferEvents = useEventListener(readContracts, "Birthday", "Transfer", localProvider, 1);
  console.log("???? Transfer events:", transferEvents);

  //
  // ???? This effect will update yourCollectibles by polling when your balance changes
  //
  const yourBalance = balance && balance.toNumber && balance.toNumber();
  const [yourCollectibles, setYourCollectibles] = useState();

  useEffect(() => {
    const updateYourCollectibles = async () => {
      const collectibleUpdate = [];
      for (let tokenIndex = 0; tokenIndex < balance; tokenIndex++) {
        try {
          console.log("GEtting token index", tokenIndex);
          const tokenId = await readContracts.Birthday.tokenOfOwnerByIndex(address, tokenIndex);
          console.log("tokenId", tokenId);
          const tokenURI = await readContracts.Birthday.tokenURI(tokenId);
          const jsonManifestString = atob(tokenURI.substring(29));
          console.log("jsonManifestString", jsonManifestString);
          /*
          const ipfsHash = tokenURI.replace("https://ipfs.io/ipfs/", "");
          console.log("ipfsHash", ipfsHash);

          const jsonManifestBuffer = await getFromIPFS(ipfsHash);

        */
          try {
            const jsonManifest = JSON.parse(jsonManifestString);
            console.log("jsonManifest", jsonManifest);
            collectibleUpdate.push({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
          } catch (e) {
            console.log(e);
          }
        } catch (e) {
          console.log(e);
        }
      }
      setYourCollectibles(collectibleUpdate.reverse());
    };
    updateYourCollectibles();
  }, [address, yourBalance]);

  const yourColorBalance = balanceColors && balanceColors.toNumber && balanceColors.toNumber();
  const [yourColors, setYourColors] = useState([]);
  const [newBirthday, setNewBirthday] = useState("loading...");
  const [newColor, setNewColor] = useState("black");
  const [colorSelection, setColorSelection] = useState(null);
  const [preview, setPreview] = useState(false);
  const [isTextWhite, setTextWhite] = useState(true);

  const Color = () => {
    return (
      <Row gutter={[8, 8]}>
        {yourColors.map(yourColors => {
          return (
            <Col span={4}>
              <ColorCard
                color={yourColors.color}
                key={yourColors.uri + "_" + yourColors.owner}
                onClick={() => {
                  setPreview(true);
                  setColorSelection(yourColors.id);
                  setNewColor(yourColors.color);
                }}
              >
                {yourColors.color}
              </ColorCard>
            </Col>
          );
        })}
      </Row>
    );
  };

  const Birthday = ({ item, id }) => {
    const [textColor, setTextColor] = useState("black");
    return (
      <>
        <Color />
        <Bounce>
          <Card
            title={
              <div>
                <span style={{ fontSize: 18, marginRight: 8 }}>{item.name}</span>
              </div>
            }
          >
            <a
              href={
                "https://testnets.opensea.io/assets/" +
                (readContracts && readContracts.Birthday && readContracts.Birthday.address) +
                "/" +
                item.id
              }
              target="_blank"
            >
              {preview ? <NFTsvg bgColor={newColor} textColor={textColor} /> : <img src={item.image} />}
            </a>
            <div>{item.description}</div>
          </Card>
        </Bounce>

        <div style={{}}>
          <div>
            <Button
              type={"primary"}
              shape="round"
              onClick={() => {
                //let id = readContracts.Birthday.tokenOfOwnerByIndex(address, o);
                tx(writeContracts.Birthday.setColor(colorSelection, id));
              }}
            >
              Change Color
            </Button>
            {/* {preview ? (
              <Button
                type={"primary"}
                shape="round"
                onClick={() => {
                  //let id = readCont
                  setPreview(false);
                }}
              >
                Toggle Preview
              </Button>
            ) : (
              <Button
                type={"primary"}
                shape="round"
                onClick={() => {
                  //let id = readCont
                  setPreview(true);
                }}
              >
                Toggle Preview{" "}
              </Button>
            )}
            {isTextWhite ? (
              <Button
                shape="round"
                type={"primary"}
                onClick={() => {
                  //tx(writeContracts.Birthday.toggleDarkmode(id));
                  setTextColor("white");
                  setTextWhite(false);
                  setPreview(true);
                }}
              >
                White Text
              </Button>
            ) : (
              <Button
                shape="round"
                type={"primary"}
                onClick={() => {
                  //tx(writeContracts.Birthday.toggleDarkmode(id));
                  setTextColor("black");
                  setTextWhite(true);
                  setPreview(true);
                }}
              >
                Black Text
              </Button>
            )}{" "} */}
          </div>
          <div></div>
        </div>
      </>
    );
  };

  useEffect(() => {
    const updateColors = async () => {
      const colorUpdate = [];
      for (let tokenIndex = 0; tokenIndex < balanceColors; tokenIndex++) {
        try {
          console.log("Getting token index", tokenIndex);
          const tokenId = await readContracts.Colors.tokenOfOwnerByIndex(address, tokenIndex);
          console.log("tokenId", tokenId);
          const tokenURI = await readContracts.Colors.tokenURI(tokenId);
          const hexColor = await readContracts.Colors.getHexColor(tokenId);
          setNewColor(hexColor);
          console.log("hexColor", hexColor);
          colorUpdate.push({ id: tokenId, uri: tokenURI, color: hexColor, owner: address });
          console.log("colors Update", colorUpdate);
          const jsonManifestString = atob(tokenURI.substring(29));
          console.log("jsonManifestString", jsonManifestString);

          /*
          const ipfsHash = tokenURI.replace("https://ipfs.io/ipfs/", "");
          console.log("ipfsHash", ipfsHash);
          const jsonManifestBuffer = await getFromIPFS(ipfsHash);
          */
          try {
            const jsonManifest = JSON.parse(jsonManifestString);
            console.log("jsonManifest", jsonManifest);
            colorUpdate.push({ id: tokenId, uri: tokenURI, color: hexColor, owner: address, ...jsonManifest });
          } catch (e) {
            console.log(e);
          }
        } catch (e) {
          console.log(e);
        }
      }
      setYourColors(colorUpdate.reverse());
    };
    updateColors();
  }, [address, yourColorBalance]);
  /*
  const addressFromENS = useResolveName(mainnetProvider, "austingriffith.eth");
  console.log("???? Resolved austingriffith.eth as:",addressFromENS)
  */

  //
  // ???? DEBUG ???????????????
  //
  useEffect(() => {
    if (
      DEBUG &&
      mainnetProvider &&
      address &&
      selectedChainId &&
      yourLocalBalance &&
      yourMainnetBalance &&
      readContracts &&
      writeContracts
    ) {
      console.log("_____________________________________ ???? scaffold-eth _____________________________________");
      console.log("???? mainnetProvider", mainnetProvider);
      console.log("???? localChainId", localChainId);
      console.log("??????????? selected address:", address);
      console.log("????????????????? selectedChainId:", selectedChainId);
      console.log("???? yourLocalBalance", yourLocalBalance ? formatEther(yourLocalBalance) : "...");
      console.log("???? yourMainnetBalance", yourMainnetBalance ? formatEther(yourMainnetBalance) : "...");
      console.log("???? readContracts", readContracts);
      console.log("???? writeContracts", writeContracts);
    }
  }, [mainnetProvider, address, selectedChainId, yourLocalBalance, yourMainnetBalance, readContracts, writeContracts]);

  let networkDisplay = "";
  if (localChainId && selectedChainId && localChainId !== selectedChainId) {
    const networkSelected = NETWORK(selectedChainId);
    const networkLocal = NETWORK(localChainId);
    if (selectedChainId === 1337 && localChainId === 31337) {
      networkDisplay = (
        <div style={{ zIndex: 2, position: "absolute", right: 0, top: 60, padding: 16 }}>
          <Alert
            message="?????? Wrong Network ID"
            description={
              <div>
                You have <b>chain id 1337</b> for localhost and you need to change it to <b>31337</b> to work with
                HardHat.
                <div>(MetaMask -&gt; Settings -&gt; Networks -&gt; Chain ID -&gt; 31337)</div>
              </div>
            }
            type="error"
            closable={false}
          />
        </div>
      );
    } else {
      networkDisplay = (
        <div style={{ zIndex: 2, position: "absolute", right: 0, top: 60, padding: 16 }}>
          <Alert
            message="?????? Wrong Network"
            description={
              <div>
                You have <b>{networkSelected && networkSelected.name}</b> selected and you need to be on{" "}
                <b>{networkLocal && networkLocal.name}</b>.
              </div>
            }
            type="error"
            closable={false}
          />
        </div>
      );
    }
  } else {
    networkDisplay = (
      <div style={{ zIndex: -1, position: "absolute", right: 154, top: 28, padding: 16, color: targetNetwork.color }}>
        {targetNetwork.name}
      </div>
    );
  }

  const loadWeb3Modal = useCallback(async () => {
    const provider = await web3Modal.connect();
    setInjectedProvider(new Web3Provider(provider));
  }, [setInjectedProvider]);

  useEffect(() => {
    if (web3Modal.cachedProvider) {
      loadWeb3Modal();
    }
  }, [loadWeb3Modal]);

  const [route, setRoute] = useState();
  useEffect(() => {
    setRoute(window.location.pathname);
  }, [setRoute]);

  let faucetHint = "";
  const faucetAvailable = localProvider && localProvider.connection && targetNetwork.name === "localhost";

  const [faucetClicked, setFaucetClicked] = useState(false);
  if (
    !faucetClicked &&
    localProvider &&
    localProvider._network &&
    localProvider._network.chainId === 31337 &&
    yourLocalBalance &&
    formatEther(yourLocalBalance) <= 0
  ) {
    faucetHint = (
      <div style={{ padding: 16 }}>
        <Button
          type="primary"
          onClick={() => {
            faucetTx({
              to: address,
              value: parseEther("1"),
            });
            setFaucetClicked(true);
          }}
        >
          ???? Grab funds from the faucet ??????
        </Button>
      </div>
    );
  }

  const [sending, setSending] = useState();
  const [ipfsHash, setIpfsHash] = useState();
  const [ipfsDownHash, setIpfsDownHash] = useState();
  const [present, setPresent] = useState();

  const [downloading, setDownloading] = useState();
  const [ipfsContent, setIpfsContent] = useState();

  const [transferToAddresses, setTransferToAddresses] = useState({});

  const [loadedAssets, setLoadedAssets] = useState();

  // Then read your DAI balance like:
  // eslint-disable-next-line spaced-comment
  /*
  const myMainnetDAIBalance = useContractReader({ DAI: mainnetDAIContract }, "DAI", "balanceOf", [
    "0x34aA3F359A9D614239015126635CE7732c18fDF3",
  ]);*/

  // eslint-disable-next-line spaced-comment
  /*useEffect(() => {
    const updateYourCollectibles = async () => {
      const assetUpdate = [];
      for (const a in assets) {
        try {
          const forSale = await readContracts.YourCollectible.forSale(utils.id(a));
          let owner;
          if (!forSale) {
            const tokenId = await readContracts.YourCollectible.uriToTokenId(utils.id(a));
            owner = await readContracts.YourCollectible.ownerOf(tokenId);
          }
          assetUpdate.push({ id: a, ...assets[a], forSale, owner });
        } catch (e) {
          console.log(e);
        }
      }
      setLoadedAssets(assetUpdate);
    };
    if (readContracts && readContracts.YourCollectible) updateYourCollectibles();
  }, [assets, readContracts, transferEvents]);*/

  const galleryList = [];

  return (
    <div className="App">
      {/* ?????? Edit the header and change the title to your project name */}
      <Header />
      {networkDisplay}

      <BrowserRouter>
        <Menu style={{ textAlign: "center" }} selectedKeys={[route]} mode="horizontal">
          <Menu.Item key="/">
            <Link
              onClick={() => {
                setRoute("/");
              }}
              to="/"
            >
              Home
            </Link>
          </Menu.Item>
          <Menu.Item key="/Present">
            <Link
              onClick={() => {
                setRoute("/Present");
              }}
              to="/Present"
            >
              Present
            </Link>
          </Menu.Item>
          <Menu.Item key="/Colors">
            <Link
              onClick={() => {
                setRoute("/Colors");
              }}
              to="/Colors"
            >
              Mint Color
            </Link>
          </Menu.Item>
          <Menu.Item key="/debug">
            <Link
              onClick={() => {
                setRoute("/debug");
              }}
              to="/debug"
            >
              Smart Contracts
            </Link>
          </Menu.Item>
        </Menu>

        <Switch>
          <Route exact path="/">
            {/*
                ???? this scaffolding is full of commonly used components
                this <Contract/> component will automatically parse your ABI
                and give you a form to interact with it locally
            */}

            <div style={{ maxWidth: 820, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
              {isSigner ? (
                <>
                  {yourBalance === 0 ? (
                    <>
                      <Input
                        style={{ maxWidth: 300 }}
                        placeholder="Input day of year during a leap year"
                        onChange={e => {
                          setNewBirthday(e.target.value);
                        }}
                      />
                      <Button
                        type={"primary"}
                        onClick={() => {
                          tx(writeContracts.Birthday.mintItem(newBirthday, { value: utils.parseEther("0.0") }));
                        }}
                      >
                        MINT
                      </Button>
                      <div style={{ margin: 32 }}>
                        <a
                          target="_blank"
                          href="https://www.esrl.noaa.gov/gmd/grad/neubrew/Calendar.jsp?view=DOY&year=2024&col=4"
                        >
                          Day of Year Calender
                        </a>
                      </div>
                    </>
                  ) : (
                    <></>
                  )}
                </>
              ) : (
                <Button type={"primary"} onClick={loadWeb3Modal}>
                  CONNECT WALLET
                </Button>
              )}
            </div>

            <div style={{ width: 820, margin: "auto", paddingBottom: 256 }}>
              {yourBalance === 0 ? (
                <> </>
              ) : (
                <List
                  bordered
                  dataSource={yourCollectibles}
                  renderItem={item => {
                    const id = item.id.toNumber();

                    console.log("IMAGE", item.image);

                    return (
                      <List.Item key={uuidv4()}>
                        <Birthday item={item} id={id} />
                      </List.Item>
                    );
                  }}
                />
              )}
            </div>
          </Route>

          <Route exact path="/Present">
            <div style={{ margin: 32 }}>
              <Input
                style={{ maxWidth: 300 }}
                placeholder="Birthday Number"
                onChange={e => {
                  setPresent(e.target.value);
                }}
              />
              <Button
                type={"primary"}
                onClick={() => {
                  tx(writeContracts.Birthday.givePresent(present, { value: utils.parseEther("0.05") }));
                }}
              >
                Give 0.05 ETH Present to Birthday Holder
              </Button>

              <div style={{ margin: 32 }}>
                <a
                  target="_blank"
                  href="https://www.esrl.noaa.gov/gmd/grad/neubrew/Calendar.jsp?view=DOY&year=2024&col=4"
                >
                  Day of Year Calender
                </a>
              </div>
            </div>
          </Route>
          <Route exact path="/Colors">
            <div style={{ padding: 32 }}>
              <Input
                style={{ maxWidth: 400 }}
                placeholder="Input any postive unclaimed token id to mint a test color"
                onChange={e => {
                  setNewBirthday(e.target.value);
                }}
              />
              <Button
                type={"primary"}
                onClick={() => {
                  tx(writeContracts.Colors.mint(newBirthday));
                }}
              >
                MINT COLOR
              </Button>
            </div>
          </Route>
          <Route path="/debug">
            {/* <div style={{ padding: 32 }}>
              <Address value={readContracts && readContracts.Birthday && readContracts.Birthday.address} />
            </div> */}
            <Contract
              name="Birthday"
              signer={userProvider.getSigner()}
              provider={localProvider}
              address={address}
              blockExplorer={blockExplorer}
            />
            {/* <div style={{ padding: 32 }}>
              <Address value={readContracts && readContracts.Colors && readContracts.Colors.address} />
            </div> */}
            <Contract
              name="Colors"
              signer={userProvider.getSigner()}
              provider={localProvider}
              address={address}
              blockExplorer={blockExplorer}
            />
          </Route>
        </Switch>
      </BrowserRouter>

      <ThemeSwitch />

      {/* ??????????? Your account is in the top right with a wallet at connect options */}
      <div style={{ position: "fixed", textAlign: "right", right: 0, top: 0, padding: 10 }}>
        <Account
          address={address}
          localProvider={localProvider}
          userProvider={userProvider}
          mainnetProvider={mainnetProvider}
          price={price}
          web3Modal={web3Modal}
          loadWeb3Modal={loadWeb3Modal}
          logoutOfWeb3Modal={logoutOfWeb3Modal}
          blockExplorer={blockExplorer}
          isSigner={isSigner}
        />
        {faucetHint}
      </div>

      {/* ???? Extra UI like gas price, eth price, faucet, and support: */}
    </div>
  );
}

/* eslint-disable */
window.ethereum &&
  window.ethereum.on("chainChanged", chainId => {
    web3Modal.cachedProvider &&
      setTimeout(() => {
        window.location.reload();
      }, 1);
  });

window.ethereum &&
  window.ethereum.on("accountsChanged", accounts => {
    web3Modal.cachedProvider &&
      setTimeout(() => {
        window.location.reload();
      }, 1);
  });
/* eslint-enable */

export default App;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:montelibero/models/chain_info.dart';
import 'package:montelibero/models/wallet_info.dart';
import 'package:montelibero/models/currency.dart';
import 'package:montelibero/models/price_list_bitcoin.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:jsonrpc_client/jsonrpc_client.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class LiquidOracle extends ChangeNotifier {
  final rpc = Client.withBasicAuth(
      GlobalConfiguration().getValue("uri"),
      GlobalConfiguration().getValue("port"),
      '1.0',
      GlobalConfiguration().getValue("user"),
      GlobalConfiguration().getValue("password"));

  ChainInfo? lastChainInfo;
  WalletInfo? lastWalletInfo;
  String infoString = "";
  String? lastAddress;

  LiquidOracle() {
    getChainData();
    getWalletInfo();
    Timer.periodic(const Duration(seconds: 1), (t) {
      getChainData();
      getWalletInfo();
    });
  }

  getChainData() async {
    var response = await rpc.call("getblockchaininfo");
    lastChainInfo = ChainInfo.fromJson(response.result);
    //infoString = response.result;
    //print(infoString);
    notifyListeners();
  }

  getWalletInfo() async {
    try {
      print('Awaiting wallet info...');
      var response = await rpc.call("getwalletinfo");
      print('Received');
      lastWalletInfo = WalletInfo.fromJson(response.result);
      print(lastWalletInfo!.assets);
      notifyListeners();
    } catch (err) {
      print(err);
      lastWalletInfo = WalletInfo(
          error: "no wallet",
          date: DateTime.now().toString(),
          name: "Not Found",
          txCount: 0,
          assets: {});
    }
  }

  Future<String> getNewAddress(String type) async {
    if (lastAddress != null) {
      return Future.value(lastAddress);
    }
    var response = null;
    try {
      response = await rpc.call("getaddressesbylabel", params: ["multisig"]);
    } catch (err) {
      print("Error requesting getaddressesbylabel " + err.toString());
    }
    try {
      if (response == null) {
        var response =
            await rpc.call("getnewaddress", params: ["multisig", type]);
        //{"result":"tlq1qqfat5d...","error":null,"id":"curltest"}
        lastAddress = response.result.toString();
        return Future.value(lastAddress);
      } else {
        lastAddress = response.result.keys.first;
        return Future.value(lastAddress);
      }
    } catch (err) {
      print("Error requesting getaddressesbylabel " + err.toString());
      return Future.value("");
    }
  }
}

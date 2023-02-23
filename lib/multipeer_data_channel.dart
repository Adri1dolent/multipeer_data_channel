library multipeer_data_channel;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:venice_core/channels/abstractions/bootstrap_channel.dart';
import 'package:venice_core/channels/abstractions/data_channel.dart';
import 'package:venice_core/channels/channel_metadata.dart';
import 'package:venice_core/channels/events/data_channel_event.dart';
import 'package:venice_core/file/file_chunk.dart';
import 'package:flutter/foundation.dart';



class MultipeerDataChannel extends DataChannel {
  MultipeerDataChannel(super.identifier);

  final methodChannel = const MethodChannel('multipeer_data_channel');

  late bool isSenderReady;

  @override
  Future<void> initReceiver(ChannelMetadata data) async {
    
    methodChannel.invokeMethod("createReceiver");
    debugPrint("[MultipeerDataChannel] reciever created");
    methodChannel.setMethodCallHandler((call) => call.method == "chunkReceived"?onChunkRecieved(call.arguments):null);
  }


  @override
  Future<void> initSender(BootstrapChannel channel) async {
    isSenderReady = false;

    methodChannel.invokeMethod('createSender');

    methodChannel.setMethodCallHandler((call) {
      if(call.method == "onPeerConnected") {
        isSenderReady = true;
      }
      return Future(() => null);
    },);

    // Send socket information to client.
    await channel.sendChannelMetadata(ChannelMetadata(super.identifier, "null", "null", "key"));

    //Wait for client to connect
    await Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: isSenderReady ? 0 : 200));
      debugPrint("[MultipeerDataChannel] Waiting for client to connect");
      return !isSenderReady;
    });

  }

  @override
  Future<void> sendChunk(FileChunk chunk) async {
    methodChannel.invokeMethod("sendChunk", <String,dynamic>{'id':chunk.identifier,'data': chunk.data});
    on(DataChannelEvent.acknowledgment, chunk.identifier);
  }

  onChunkRecieved(arguments) {
    //debugPrint("[MultipeerDataChannel] Chunk ${arguments["id"]} received");
    int id = arguments["id"];
    Uint8List data = arguments["data"];
    FileChunk fc = FileChunk(identifier: id, data: data);
    on(DataChannelEvent.data, fc);
  }

}
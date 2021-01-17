import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:testgps/the_toast.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin{
  String positionUrl = "";
  Position finalPosition;
  bool isFilterEnabled = false;
  AnimationController _controller;
  Animation _animation;
  //second value = 0 ; minute value = 1
  int delayIndex = 0;
  double delayValue = 300;
  @override
  void initState() {
    _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500)
    );
    _animation = Tween(
      begin: 0.0,
      end: 1.0
    ).animate(_controller);
    _determinePosition();
    super.initState();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return Scaffold(
      body: Body()
    );
  }

  Widget Body() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        filterChoiceWidget(),
        filterWidget(),
        SizedBox(height: 15),
        Text(finalPosition == null ? 'No position found' : finalPosition.latitude.toString() + ', ' + finalPosition.longitude.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
        sendButton()
      ],
    );
  }

  Widget filterChoiceWidget() => Center(
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      width: double.infinity,
      child: RaisedButton(
        elevation: 0,
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
        child: Text("Set Time Interval", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        onPressed: () {
          setState(() {
            isFilterEnabled = !isFilterEnabled;
          });
        },
      ),
    ),
  );

  Widget filterWidget() => isFilterEnabled == true ? FadeTransition(
      opacity: _animation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.blue.shade50,
          shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Column(
              children: [
                Center(
                  child: Text('In seconds (${delayValue.round()} s)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),),
                ),
                Slider(
                  min: 1,
                  max: 1000,
                  onChanged: (double value) {
                    setState(() {
                      delayValue = value;
                    });
                  },
                  value: delayValue,
                ),
                /*SizedBox(height: 17,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        RaisedButton(
                            elevation: 0,
                            color: delayIndex == 0 ? Theme.of(context).primaryColor : Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                            shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
                            child: Text("Seconde", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: delayIndex == 0 ? Colors.white : Theme.of(context).primaryColor)),
                            onPressed: () {
                              setState(() {
                                delayIndex = 0;
                              });
                              //_determinePosition();
                            },
                          ),
                          SizedBox(width: 15),
                          RaisedButton(
                            elevation: 0,
                            color: delayIndex == 1 ? Theme.of(context).primaryColor : Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                            shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
                            child: Text("Minute", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: delayIndex == 1 ? Colors.white : Theme.of(context).primaryColor)),
                            onPressed: () {
                              setState(() {
                                delayIndex = 1;
                              });
                              //_determinePosition();
                            },
                          ),
                        ],
                      ),*/
              ],
            ),
          ),
        ),
      ),
    ) : Container();

  Widget sendButton() => Container(
    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    width: double.infinity,
    child: RaisedButton(
      elevation: 0,
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
      child: Text("Send Position", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
      onPressed: () {
        _sendPosition();
      },
    ),
  );

  Future _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return _showDialog(context, "GPS disabled");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permantly denied, we cannot request permissions.');
      return _showDialog(context, "GPS access denied");
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print('Location permissions are denied (actual value: $permission).');
        return _showDialog(context, "GPS access denied");
      }
    }

    return Geolocator.getPositionStream(intervalDuration: Duration(seconds: delayValue.round())).listen(
            (Position position) async {
          setState(() {
            finalPosition = position;
          });
          _sendPosition();
          print(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());
        });
  }

  _showDialog(context, message) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        String title = "WARNING";
        return AlertDialog(
          shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(title, style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.bold)),
          content: Text(message, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
        );
      },
    );
  }

  _sendPosition() async {
    await http
        .post(positionUrl,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "lat": finalPosition.latitude,
          "lng": finalPosition.longitude
        }))
        .then((value) {
          print(value.statusCode);
      if(value.statusCode == 200) {
        return theToast("Position send successfully", context);
      } else {
        return theToast("An error has occured", context);
      }
    });
  }
}

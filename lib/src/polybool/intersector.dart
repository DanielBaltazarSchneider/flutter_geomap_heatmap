import 'package:dart_jts/dart_jts.dart' as jts;

import 'epsilon.dart';
import 'linked_list.dart';
import 'segment_fill.dart';
import 'types.dart';

class Intersecter {
  bool selfIntersection = false;

  //BuildLog buildLog;

  EventLinkedList eventRoot = EventLinkedList();
  StatusLinkedList? statusRoot;

  Intersecter(this.selfIntersection);

  Segment segmentNew(jts.Coordinate start, jts.Coordinate end) {
    return Segment(id: -1, start: start, end: end, myFill: SegmentFill(), otherFill: null);
  }

  Segment segmentCopy(jts.Coordinate start, jts.Coordinate end, Segment seg) {
    return Segment(id: -1, start: start, end: end, myFill: SegmentFill(above: seg.myFill.above, below: seg.myFill.below), otherFill: null);
  }

  void eventAdd(EventNode ev, jts.Coordinate otherPt) {
    eventRoot.insertBefore(ev, otherPt);
  }

  EventNode eventAddSegmentStart(Segment seg, bool primary) {
    var evStart = EventNode(isStart: true, pt: seg.start, seg: seg, primary: primary, other: null, status: null);

    eventAdd(evStart, seg.end);

    return evStart;
  }

  EventNode eventAddSegmentEnd(EventNode evStart, Segment seg, bool primary) {
    var evEnd = EventNode(isStart: false, pt: seg.end, seg: seg, primary: primary, other: evStart, status: null);

    evStart.other = evEnd;

    eventAdd(evEnd, evStart.pt!);

    return evEnd;
  }

  EventNode eventAddSegment(Segment seg, bool primary) {
    var evStart = eventAddSegmentStart(seg, primary);
    eventAddSegmentEnd(evStart, seg, primary);

    return evStart;
  }

  void eventUpdateEnd(EventNode ev, jts.Coordinate end) {
    // slides an end backwards
    //   (start)------------(end)    to:
    //   (start)---(end)

    // if (buildLog != null) {
    //   buildLog.segmentChop(ev.seg, end);
    // }

    ev.other?.remove();
    ev.seg?.end = end;
    ev.other?.pt = end;
    eventAdd(ev.other!, ev.pt!);
  }

  EventNode eventDivide(EventNode ev, jts.Coordinate pt) {
    var ns = segmentCopy(pt, ev.seg!.end, ev.seg!);
    eventUpdateEnd(ev, pt);

    return eventAddSegment(ns, ev.primary);
  }

  SegmentList calculate({bool inverted = false}) {
    if (!selfIntersection) {
      throw Exception("This function is only intended to be called when selfIntersection = true");
    }

    return calculateINTERNAL(inverted, false);
  }

  SegmentList calculateXD(SegmentList segments1, bool inverted1, SegmentList segments2, bool inverted2) {
    if (selfIntersection) {
      throw Exception("This function is only intended to be called when selfIntersection = false");
    }

    // segmentsX come from the self-intersection API, or this API
    // invertedX is whether we treat that list of segments as an inverted polygon or not
    // returns segments that can be used for further operations
    for (int i = 0; i < segments1.length; i++) {
      eventAddSegment(segments1[i], true);
    }
    for (int i = 0; i < segments2.length; i++) {
      eventAddSegment(segments2[i], false);
    }

    return calculateINTERNAL(inverted1, inverted2);
  }

  void addRegion(List<jts.Coordinate> region) {
    if (!selfIntersection) {
      throw Exception("The addRegion() function is only intended for use when selfIntersection = false");
    }

    // Ensure that the polygon is fully closed (the start point and end point are exactly the same)
    if (!Epsilon().pointsSame(region[region.length - 1], region[0])) {
      region.add(region[0]);
    }

    // regions are a list of points:
    //  [ [0, 0], [100, 0], [50, 100] ]
    // you can add multiple regions before running calculate
    var pt1 = jts.Coordinate(0, 0);
    var pt2 = region[region.length - 1];

    for (var i = 0; i < region.length; i++) {
      pt1 = pt2;
      pt2 = region[i];

      var forward = Epsilon().pointsCompare(pt1, pt2);
      if (forward == 0) {
        continue;
      } // just skip it

      eventAddSegment(segmentNew(forward < 0 ? pt1 : pt2, forward < 0 ? pt2 : pt1), true);
    }
  }

  Transition? statusFindSurrounding(EventNode ev) {
    return statusRoot?.findTransition(ev);
  }

  EventNode? checkIntersection(EventNode ev1, EventNode ev2) {
    // returns the segment equal to ev1, or false if nothing equal

    var seg1 = ev1.seg;
    var seg2 = ev2.seg;
    var a1 = seg1!.start;
    var a2 = seg1.end;
    var b1 = seg2!.start;
    var b2 = seg2.end;

    // if (buildLog != null) buildLog.checkIntersection(seg1, seg2);

    Intersection intersect;
    Map<bool, Intersection> result = Epsilon().linesIntersectAsMap(a1, a2, b1, b2);
    intersect = result.values.first;
    bool resultX = result.keys.first;

    if (!resultX) {
      // segments are parallel or coincident

      // if points aren't collinear, then the segments are parallel, so no intersections
      if (!Epsilon().pointsCollinear(a1, a2, b1)) return null;

      // otherwise, segments are on top of each other somehow (aka coincident)

      if (Epsilon().pointsSame(a1, b2) || Epsilon().pointsSame(a2, b1)) return null; // segments touch at endpoints... no intersection

      var a1EquB1 = Epsilon().pointsSame(a1, b1);
      var a2EquB2 = Epsilon().pointsSame(a2, b2);

      if (a1EquB1 && a2EquB2) return ev2; // segments are exactly equal

      var a1Between = !a1EquB1 && Epsilon().pointBetween(a1, b1, b2);
      var a2Between = !a2EquB2 && Epsilon().pointBetween(a2, b1, b2);

      // handy for debugging:
      // buildLog.log({
      //	a1_equ_b1: a1_equ_b1,
      //	a2_equ_b2: a2_equ_b2,
      //	a1_between: a1_between,
      //	a2_between: a2_between
      // });

      if (a1EquB1) {
        if (a2Between) {
          //  (a1)---(a2)
          //  (b1)----------(b2)
          eventDivide(ev2, a2);
        } else {
          //  (a1)----------(a2)
          //  (b1)---(b2)
          eventDivide(ev1, b2);
        }

        return ev2;
      } else if (a1Between) {
        if (!a2EquB2) {
          // make a2 equal to b2
          if (a2Between) {
            //         (a1)---(a2)
            //  (b1)-----------------(b2)
            eventDivide(ev2, a2);
          } else {
            //         (a1)----------(a2)
            //  (b1)----------(b2)
            eventDivide(ev1, b2);
          }
        }

        //         (a1)---(a2)
        //  (b1)----------(b2)
        eventDivide(ev2, a1);
      }
    } else {
      // otherwise, lines intersect at i.pt, which may or may not be between the endpoints

      // is A divided between its endpoints? (exclusive)
      if (intersect.alongA == 0) {
        if (intersect.alongB == -1) {
          eventDivide(ev1, b1);
        } else if (intersect.alongB == 0) {
          eventDivide(ev1, intersect.pt!);
        } else if (intersect.alongB == 1) {
          eventDivide(ev1, b2);
        }
      }

      // is B divided between its endpoints? (exclusive)
      if (intersect.alongB == 0) {
        if (intersect.alongA == -1) {
          eventDivide(ev2, a1);
        } else if (intersect.alongA == 0) {
          eventDivide(ev2, intersect.pt!);
        } else if (intersect.alongA == 1) {
          eventDivide(ev2, a2);
        }
      }
    }

    return null;
  }

  EventNode? checkBothIntersections(EventNode ev, EventNode? above, EventNode? below) {
    if (above != null) {
      var eve = checkIntersection(ev, above);
      if (eve != null) return eve;
    }

    if (below != null) {
      return checkIntersection(ev, below);
    }

    return null;
  }

  SegmentList calculateINTERNAL(bool primaryPolyInverted, bool secondaryPolyInverted) {
    //
    // main event loop
    //
    var segments = SegmentList();

    statusRoot = StatusLinkedList();

    while (!eventRoot.isEmpty) {
      var ev = eventRoot.head;

      //if (buildLog != null) buildLog.vert(ev.pt.x);

      if (ev.isStart) {
        // if (buildLog != null) {
        //   buildLog.segmentNew(ev.seg, ev.primary);
        // }

        var surrounding = statusFindSurrounding(ev);
        var above = surrounding?.before;
        var below = surrounding?.after;

        // if( buildLog != null )
        // {
        // buildLog.tempStatus(
        // ev.seg,
        // above != null ? above.seg : (object)false,
        // below != null ? below.seg : (object)false
        // );
        // }

        var eve = checkBothIntersections(ev, above, below);
        if (eve != null) {
          // ev and eve are equal
          // we'll keep eve and throw away ev

          // merge ev.seg's fill information into eve.seg

          if (selfIntersection) {
            var toggle = false; // are we a toggling edge?
            if (ev.seg?.myFill.below == null) {
              toggle = true;
            } else {
              toggle = ev.seg?.myFill.above != ev.seg?.myFill.below;
            }

            // merge two segments that belong to the same polygon
            // think of this as sandwiching two segments together, where `eve.seg` is
            // the bottom -- this will cause the above fill flag to toggle
            if (toggle) {
              eve.seg!.myFill.above = !eve.seg!.myFill.above;
            }
          } else {
            // merge two segments that belong to different polygons
            // each segment has distinct knowledge, so no special logic is needed
            // note that this can only happen once per segment in this phase, because we
            // are guaranteed that all self-intersections are gone
            eve.seg?.otherFill = ev.seg?.myFill;
          }

          // if (buildLog != null) {
          //   buildLog.segmentUpdate(eve.seg);
          // }

          ev.other?.remove();
          ev.remove();
        }

        if (eventRoot.head != ev) {
          // something was inserted before us in the event queue, so loop back around and
          // process it before continuing
          // if (buildLog != null) {
          //   buildLog.rewind(ev.seg);
          // }

          continue;
        }

        //
        // calculate fill flags
        //
        if (selfIntersection) {
          bool toggle = false; // are we a toggling edge?

          // if we are a new segment...
          if (ev.seg?.myFill.below == null) {
            toggle = true;
          } else {
            toggle = ev.seg?.myFill.above != ev.seg!.myFill.below;
          } // calculate toggle

          // next, calculate whether we are filled below us
          if (below == null) {
            // if nothing is below us...
            // we are filled below us if the polygon is inverted
            ev.seg?.myFill.below = primaryPolyInverted;
          } else {
            // otherwise, we know the answer -- it's the same if whatever is below
            // us is filled above it
            ev.seg?.myFill.below = below.seg!.myFill.above;
          }

          // since now we know if we're filled below us, we can calculate whether
          // we're filled above us by applying toggle to whatever is below us
          if (toggle) {
            ev.seg?.myFill.above = ev.seg?.myFill.below != null ? !ev.seg!.myFill.below! : ev.seg!.myFill.above;
          } else {
            ev.seg?.myFill.above = ev.seg?.myFill.below != null ? ev.seg!.myFill.below! : ev.seg!.myFill.above;
          }
        } else {
          // now we fill in any missing transition information, since we are all-knowing
          // at this point

          if (ev.seg?.otherFill == null) {
            // if we don't have other information, then we need to figure out if we're
            // inside the other polygon
            var inside = false;
            if (below == null) {
              // if nothing is below us, then we're inside if the other polygon is
              // inverted
              inside = ev.primary ? secondaryPolyInverted : primaryPolyInverted;
            } else {
              // otherwise, something is below us
              // so copy the below segment's other polygon's above
              if (ev.primary == below.primary) {
                inside = below.seg!.otherFill!.above;
              } else {
                inside = below.seg!.myFill.above;
              }
            }

            ev.seg?.otherFill = SegmentFill(above: inside, below: inside);
          }
        }

        // if( buildLog != null )
        // {
        // buildLog.status(
        // ev.seg,
        // above != null ? above.seg : (object)false,
        // below != null ? below.seg : (object)false
        // );
        // }

        // insert the status and remember it for later removal
        ev.other?.status = statusRoot?.insert(surrounding!, ev);
      } else {
        var st = ev.status;

        if (st == null) {
          throw Exception("PolyBool: Zero-length segment detected; your epsilon is probably too small or too large");
        }

        // removing the status will create two new adjacent edges, so we'll need to check
        // for those
        if (statusRoot!.exists(st.prev) && statusRoot!.exists(st.next)) checkIntersection(st.prev!.ev!, st.next!.ev!);

        // if (buildLog != null) buildLog.statusRemove(st.ev.seg);

        // remove the status
        st.remove();

        // if we've reached this point, we've calculated everything there is to know, so
        // save the segment for reporting
        if (!ev.primary) {
          // make sure `seg.myFill` actually points to the primary polygon though
          var s = ev.seg!.myFill;
          ev.seg?.myFill = ev.seg!.otherFill!;
          ev.seg?.otherFill = s;
        }

        segments.add(ev.seg!);
      }

      // remove the event and continue
      eventRoot.head.remove();
    }

    // if (buildLog != null) {
    //   buildLog.done();
    // }

    return segments;
  }
}

import 'package:dart_jts/dart_jts.dart' as jts;

import 'epsilon.dart';
import 'types.dart';

class EventNode {
  bool isStart;
  jts.Coordinate? pt;
  Segment? seg;
  bool primary;
  EventNode? other;
  StatusNode? status;

  EventNode? next;
  EventNode? prev;

  EventNode({this.isStart = false, this.pt, this.seg, this.primary = false, this.other, this.status, this.next, this.prev});

  void remove() {
    prev?.next = next;

    if (next != null) {
      next?.prev = prev;
    }

    prev = null;
    next = null;
  }
}

class StatusNode {
  EventNode? ev;

  StatusNode? next;
  StatusNode? prev;

  void remove() {
    prev?.next = next;

    if (next != null) {
      next?.prev = prev;
    }

    prev = null;
    next = null;
  }

  StatusNode({this.ev, this.next, this.prev});
}

class StatusLinkedList {
  StatusNode? root = StatusNode();

  StatusNode? get head {
    return root?.next;
  }

  bool get isEmpty {
    return root?.next == null;
  }

  bool exists(StatusNode? node) {
    if (node == null || node == root) return false;

    return true;
  }

  Transition? findTransition(EventNode ev) {
    StatusNode? prev = root;
    StatusNode? here = root?.next;

    while (here != null) {
      if (findTransitionPredicate(ev, here)) break;

      prev = here;
      here = here.next;
    }

    return Transition(before: prev == root ? null : prev?.ev, after: here?.ev, prev: prev, here: here);
  }

  StatusNode insert(Transition surrounding, EventNode ev) {
    var prev = surrounding.prev;
    var here = surrounding.here;

    var node = StatusNode(ev: ev);

    node.prev = prev;
    node.next = here;
    prev?.next = node;

    if (here != null) {
      here.prev = node;
    }

    return node;
  }

  bool findTransitionPredicate(EventNode ev, StatusNode here) {
    var comp = statusCompare(ev, here.ev!);
    return comp > 0;
  }

  int statusCompare(EventNode ev1, EventNode ev2) {
    var a1 = ev1.seg!.start;
    var a2 = ev1.seg!.end;
    var b1 = ev2.seg!.start;
    var b2 = ev2.seg!.end;

    if (Epsilon().pointsCollinear(a1, b1, b2)) {
      if (Epsilon().pointsCollinear(a2, b1, b2)) return 1; //eventCompare(true, a1, a2, true, b1, b2);

      return Epsilon().pointAboveOrOnLine(a2, b1, b2) ? 1 : -1;
    }

    return Epsilon().pointAboveOrOnLine(a1, b1, b2) ? 1 : -1;
  }
}

class EventLinkedList {
  EventNode root = EventNode();

  EventNode get head {
    return root.next!;
  }

  bool get isEmpty {
    return root.next == null;
  }

  void insertBefore(EventNode node, jts.Coordinate otherPt) {
    var last = root;
    var here = root.next;

    while (here != null) {
      if (insertBeforePredicate(here, node, otherPt)) {
        node.prev = here.prev;
        node.next = here;
        here.prev!.next = node;
        here.prev = node;

        return;
      }

      last = here;
      here = here.next;
    }

    last.next = node;
    node.prev = last;
    node.next = null;
  }

  bool insertBeforePredicate(EventNode here, EventNode ev, jts.Coordinate otherPt) {
    // should ev be inserted before here?
    var comp = eventCompare(ev.isStart, ev.pt!, otherPt, here.isStart, here.pt!, here.other!.pt!);

    return comp < 0;
  }

  int eventCompare(bool p1IsStart, jts.Coordinate p1_1, jts.Coordinate p1_2, bool p2IsStart, jts.Coordinate p2_1, jts.Coordinate p2_2) {
    // compare the selected points first
    // compare the selected points first
    var comp = Epsilon().pointsCompare(p1_1, p2_1);
    if (comp != 0) return comp;

    // the selected points are the same

    if (Epsilon().pointsSame(p1_2, p2_2)) {
      return 0;
    } // then the segments are equal

    if (p1IsStart != p2IsStart) {
      return p1IsStart ? 1 : -1;
    } // favor the one that isn't the start

    // otherwise, we'll have to calculate which one is below the other manually
    return Epsilon().pointAboveOrOnLine(
            p1_2,
            p2IsStart ? p2_1 : p2_2, // order matters
            p2IsStart ? p2_2 : p2_1)
        ? 1
        : -1;
  }
}

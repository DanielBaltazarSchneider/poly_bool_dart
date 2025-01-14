// provides the raw computation functions that takes epsilon into account
//
// zero is defined to be between (-epsilon, epsilon) exclusive
//

import 'dart:math' as math;

import 'package:dart_jts/dart_jts.dart' as jts;

import 'types.dart';

class Epsilon {
  static const eps = 0.0000000001; // sane default? sure why not

  bool pointAboveOrOnLine(jts.Coordinate pt, jts.Coordinate left, jts.Coordinate right) {
    double ax = left.x;
    double ay = left.y;
    double bx = right.x;
    double by = right.y;
    double cx = pt.x;
    double cy = pt.y;
    double abx = bx - ax;
    double aby = by - ay;
    double ab = math.sqrt(abx * abx + aby * aby);
    // algebraic distance of 'pt' to ('left', 'right') line is:
    // [ABx * (Cy - Ay) - ABy * (Cx - Ax)] / AB
    return abx * (cy - ay) - aby * (cx - ax) >= -eps * ab;
  }

  bool pointBetween(jts.Coordinate p, jts.Coordinate left, jts.Coordinate right) {
    // p must be collinear with left->right
    // returns false if p == left, p == right, or left == right
    if (pointsSame(p, left) || pointsSame(p, right)) return false;
    double dPyLy = p.y - left.y;
    double dRxLx = right.x - left.x;
    double dPxLx = p.x - left.x;
    double dRyLy = right.y - left.y;

    double dot = dPxLx * dRxLx + dPyLy * dRyLy;
    // dot < 0 is p is to the left of 'left'
    if (dot < 0) return false;
    double sqlen = dRxLx * dRxLx + dRyLy * dRyLy;
    // dot <= sqlen is p is to the left of 'right'
    return dot <= sqlen;
  }

  bool pointsSameX(jts.Coordinate p1, jts.Coordinate p2) {
    return (p1.x - p2.x).abs() < eps;
  }

  bool pointsSameY(jts.Coordinate p1, jts.Coordinate p2) {
    return (p1.y - p2.y).abs() < eps;
  }

  bool pointsSame(jts.Coordinate p1, jts.Coordinate p2) {
    return pointsSameX(p1, p2) && pointsSameY(p1, p2);
  }

  int pointsCompare(jts.Coordinate p1, jts.Coordinate p2) {
    // returns -1 if p1 is smaller, 1 if p2 is smaller, 0 if equal
    if (pointsSameX(p1, p2)) return pointsSameY(p1, p2) ? 0 : (p1.y < p2.y ? -1 : 1);
    return p1.x < p2.x ? -1 : 1;
  }

  bool pointsCollinear(jts.Coordinate pt1, jts.Coordinate pt2, jts.Coordinate pt3) {
    // does pt1->pt2->pt3 make a straight line?
    // essentially this is just checking to see if the slope(pt1->pt2) === slope(pt2->pt3)
    // if slopes are equal, then they must be collinear, because they share pt2
    double dx1 = pt1.x - pt2.x;
    double dy1 = pt1.y - pt2.y;
    double dx2 = pt2.x - pt3.x;
    double dy2 = pt2.y - pt3.y;
    double n1 = math.sqrt(dx1 * dx1 + dy1 * dy1);
    double n2 = math.sqrt(dx2 * dx2 + dy2 * dy2);
    // Assuming det(u, v) = 0, we have:
    // |det(u + u_err, v + v_err)| = |det(u + u_err, v + v_err) - det(u,v)|
    // =|det(u, v_err) + det(u_err. v) + det(u_err, v_err)|
    // <= |det(u, v_err)| + |det(u_err, v)| + |det(u_err, v_err)|
    // <= N(u)N(v_err) + N(u_err)N(v) + N(u_err)N(v_err)
    // <= eps * (N(u) + N(v) + eps)
    // We have N(u) ~ N(u + u_err) and N(v) ~ N(v + v_err).
    // Assuming eps << N(u) and eps << N(v), we end with:
    // |det(u + u_err, v + v_err)| <= eps * (N(u + u_err) + N(v + v_err))
    return (dx1 * dy2 - dx2 * dy1).abs() <= eps * (n1 + n2);
  }

  Map<bool, Intersection> linesIntersectAsMap(jts.Coordinate a0, jts.Coordinate a1, jts.Coordinate b0, jts.Coordinate b1) {
    Intersection intersection;
    // returns false if the lines are coincident (e.g., parallel or on top of each other)
    //
    // returns an object if the lines intersect:
    //   {
    //     pt: [x, y],    where the intersection point is at
    //     alongA: where intersection point is along A,
    //     alongB: where intersection point is along B
    //   }
    //
    //  alongA and alongB will each be one of: -2, -1, 0, 1, 2
    //
    //  with the following meaning:
    //
    //    -2   intersection point is before segment's first point
    //    -1   intersection point is directly on segment's first point
    //     0   intersection point is between segment's first and second points (exclusive)
    //     1   intersection point is directly on segment's second point
    //     2   intersection point is after segment's second point

    double adx = a1.x - a0.x;
    double ady = a1.y - a0.y;
    double bdx = b1.x - b0.x;
    double bdy = b1.y - b0.y;

    double axb = adx * bdy - ady * bdx;
    double n1 = math.sqrt(adx * adx + ady * ady);
    double n2 = math.sqrt(bdx * bdx + bdy * bdy);
    if ((axb).abs() <= eps * (n1 + n2)) {
      intersection = Intersection.empty;
      return {false: intersection}; // lines are coincident

    }

    double dx = a0.x - b0.x;
    double dy = a0.y - b0.y;

    double A = (bdx * dy - bdy * dx) / axb;
    double B = (adx * dy - ady * dx) / axb;

    jts.Coordinate pt = jts.Coordinate(a0.x + A * adx, a0.y + A * ady);
    intersection = Intersection(alongA: 0, alongB: 0, pt: pt);

    // categorize where intersection point is along A and B

    if (pointsSame(pt, a0)) {
      intersection.alongA = -1;
    } else if (pointsSame(pt, a1)) {
      intersection.alongA = 1;
    } else if (A < 0) {
      intersection.alongA = -2;
    } else if (A > 1) {
      intersection.alongA = 2;
    }

    if (pointsSame(pt, b0)) {
      intersection.alongB = -1;
    } else if (pointsSame(pt, b1)) {
      intersection.alongB = 1;
    } else if (B < 0) {
      intersection.alongB = -2;
    } else if (B > 1) {
      intersection.alongB = 2;
    }

    return {true: intersection};
  }
}

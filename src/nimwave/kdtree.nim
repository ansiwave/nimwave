## https://github.com/jblindsay/kdtree
##
## MIT License
##
## Copyright (c) 2020 John Lindsay
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
##
##
## kdtree is a pure Nim k-d tree implementation. k-d trees are data structures for performing
## efficient spatial query operations on point data sets.
## 
## .. code-block:: nim
##   import random, strformat
##   import kdtree
## 
##   let numPoints = 100_000
##   var
##     points = newSeqOfCap[array[2, float]](numPoints)
##     values = newSeqOfCap[int](numPoints)
##     x: float
##     y: float
##     r = initRand(34)
## 
##   for a in 0..<numPoints:
##     x = r.rand(100.0)
##     y = r.rand(100.0)
##     points.add([x, y])
##     values.add(a)
## 
##   echo fmt"Building tree of {numPoints} random points..."
##   var tree = newKdTree[int](points, values)
## 
##   # Perform nearestNeighour searches
##   let numSearches = 10_000
##   for a in 0..<numSearches:
##     x = r.rand(100.0)
##     y = r.rand(100.0)
##     let (pt, values, dist) = tree.nearestNeighbour([x, y])
##     echo fmt"point={pt}, value={value}, dist={dist}"
## 
##   # Perform nearestNeighours searches
##   let n = 10
##   for a in 0..<numSearches:
##     x = r.rand(100.0)
##     y = r.rand(100.0)
##     let ret = tree.nearestNeighbours([x, y], n)
##     for (pt, value, dist) in ret:
##       echo fmt"point={pt}, value={value}, dist={dist}"
## 
##   # Perform withinRadius searches
##   var ret2 = tree.withinRadius([point.x, point.y], radius=5.0, sortResults=true)
##   for (pt, value, dist) in ret2:
##     echo fmt"point={pt}, value={value}, dist={dist}"
## 
##   # Perform withinRange searches
##   var 
##     min: array[2, float] = [0.0, 0.0]
##     max: array[2, float] = [10.0, 10.0]
##     hyperRect = newHyperRectangle(min, max)
##   
##   var ret = tree.withinRange(hyperRect)
##   for (pt, value) in ret:
##     echo fmt"point={pt}, value={value}"

import algorithm, math
# import strformat

const K* = 3
  ## K is the dimensionality of the points in this package's K-D trees.

type KdPoint* = 
      array[K, float]
      ## A KdPoint is a location in K-dimensional space.

# sqrDist returns the square distance between two points.
func sqrDist(self, other: KdPoint): float =
    result = 0.0
    for i in 0..<K:
        result += (self[i] - other[i]) * (self[i] - other[i])

type DistFunc* = 
    proc (x, y: KdPoint): float {.closure.}
    ## A distance function used to calculate the distance between two KdPoints, returning a float

type KdNode[T] = ref object
    left, right: KdNode[T]
    point: KdPoint
    data: T
    splitDimension: int

func newNode[T](point: KdPoint, data: T): KdNode[T] =
    new(result)
    result.point = point
    result.data = data

type KdTree*[T] = object
    ## A k-d tree data structure that allows efficient spatial querying on point distributions. The
    ## Current implementation is designed for 2-D point data, although other dimensionality is possible
    ## simply by modifying the const `K`.
    root*: KdNode[T]
    len: int
    distFunc: DistFunc

func buildTree[T](nodes: var seq[KdNode[T]], depth = 0): KdNode[T] =
    let numPoints = len(nodes)
    if numPoints > 2:
        let split = depth mod K
        proc kdNodeCmp(x, y: KdNode[T]): int =
            if x.point[split] < y.point[split]: -1
            elif x.point[split] == y.point[split]: 0
            else: 1

        nodes.sort(kdNodeCmp)
        let m = (numPoints / 2).int
        result = nodes[m]

        result.splitDimension = split
        var left = nodes[0..m-1]
        result.left = buildTree(left, depth+1)
        var right = nodes[m+1..high(nodes)]
        result.right = buildTree(right, depth+1)
    elif numPoints == 2:
        let split = depth mod K
        if nodes[0].point[split] > nodes[1].point[split]:
            result = nodes[1]
            result.right = nodes[0]
        else:
            result = nodes[0]
            result.right = nodes[1]

        result.left = nil
    elif numPoints == 1:
        result = nodes[0]
    else:
        result = nil

func newKdTree*[T](pointData: openArray[(KdPoint, T)], distFunc: DistFunc = sqrDist): KdTree[T] =
    ## Constructs a k-d tree by bulk-loading an array of point-data tuples, where the associated data is 
    ## of any generic type `T`. Notice that this way of constructing a KdTree should be preferred over 
    ## adding points individually because the resulting tree will be balanced, which will make for more 
    ## efficient search operations. The default `distFunc` is the squared distance, which is returned from each
    ## search function.
    ## 
    ## .. code-block:: nim
    ##  let pointsAndValues = [([2.0, 3.0], 1), 
    ##                        ([5.0, 4.0], 2), 
    ##                        ([9.0, 6.0], 3), 
    ##                        ([4.0, 7.0], 4), 
    ##                        ([8.0, 1.0], 5), 
    ##                        ([7.0, 2.0], 6)]
    ## 
    ##  var tree = newKdTree[int](pointsAndValues)
    ##  
    ##  # A custom distance function; the default is a squared distance
    ##  proc myDistFunc(self, other: array[2, float]): float =
    ##    result = 0.0
    ##    for i in 0..<len(self):
    ##      result += (self[i] - other[i]) * (self[i] - other[i])
    ##    result = sqrt(result)
    ##
    ##  var tree = newKdTree[int](pointsAndValues, distFunc=myDistFunc)

    doAssert len(pointData) > 0, "The point data appears to be empty."

    var nodes = newSeqOfCap[KdNode[T]](len(pointData))
    for p in pointData:
        nodes.add(newNode(p[0], p[1]))

    result.root = buildTree(nodes)
    result.len = len(nodes)
    result.distFunc = distFunc

func newKdTree*[T](points: openArray[KdPoint], data: openArray[T], distFunc: DistFunc = sqrDist): KdTree[T] =
    ## Constructs a k-d tree by bulk-loading arrays of points and associated data values of any generic 
    ## type `T`. Notice that this way of constructing a KdTree should be preferred over adding points 
    ## individually because the resulting tree will be balanced, which will make for more efficient 
    ## search operations. The default `distFunc` is the squared distance, which is returned from each
    ## search function.
    ## 
    ## .. code-block:: nim
    ##  let points = [[2.0, 3.0], [5.0, 4.0], [9.0, 6.0], [4.0, 7.0], [8.0, 1.0], [7.0, 2.0]]
    ##  let values = [1, 2, 3, 4, 5, 6]
    ## 
    ##  var tree = newKdTree[int](points, values)
    ## 
    ##  # A custom distance function; the default is a squared distance
    ##  proc myDistFunc(self, other: array[2, float]): float =
    ##    result = 0.0
    ##    for i in 0..<len(self):
    ##      result += (self[i] - other[i]) * (self[i] - other[i])
    ##    result = sqrt(result)
    ##
    ##  var tree = newKdTree[int](points, values, distFunc=myDistFunc)

    doAssert len(points) == len(data), "Points and data arrays must be the same size."
    doAssert len(points) > 0, "Point data appears to be empty"

    var nodes = newSeqOfCap[KdNode[T]](len(points))
    for i in 0..<len(points):
        nodes.add(newNode(points[i], data[i]))

    result.root = buildTree(nodes)
    result.len = len(nodes)
    result.distFunc = distFunc

func add*[T](tree: var KdTree[T], point: KdPoint, data: T) = 
    ## This function can be used to add single points, and their associated data of type `T`
    ## to an existing KdTree object. Notice that this can result in an unbalanced tree which
    ## is suboptimal for search operation efficiency. 

    var node = newNode(point, data)
    var it = tree.root
    var depth = 0
    while it != nil:
        if node.point[it.splitDimension] <= it.point[it.splitDimension]:
            if it.left == nil:
                node.splitDimension = (depth + 1) mod K
                it.left = node
                return
            it = it.left
        else:
            if it.right == nil:
                node.splitDimension = (depth + 1) mod K
                it.right = node
                return
            it = it.right

        depth += 1

    tree.len += 1

func len*[T](tree: KdTree[T]): int = 
  ## Returns the number of nodes contained within the KdTree.
  tree.len

func height[T](node: var KdNode[T]): int =
    if node == nil:
        return 0

    var lht = node.left.height()
    var rht = node.right.height()
    result = max(lht, rht) + 1
    
func height*[T](tree: var KdTree[T]): int =
    ## Returns the height of the KdTree.
    
    result = height(tree.root)

func isBalanced*[T](tree: var KdTree[T]): int =
    ## Returns the value of the left tree height - right tree height. The larger the 
    ## value magnitude, the more unbalanced the tree is (some say an unbalanced tree 
    ## is any with an absolute magnitude greater than 1). The sign indicates the direction
    ## of skew, with negative values indicating a left-skewed tree and positive values
    ## indicated a right-skewed tree.

    result = height(tree.root.left) - height(tree.root.right)

func rebalance*[T](tree: var KdTree[T]) =
    ## Re-balances an unbalanced KdTree. Note that the original tree structure can be 
    ## completely modified by this function. Use this function after adding a significant
    ## number of individual nodes to the tree with the `add` function.

    # collect all the tree's nodes
    var nodes = newSeqOfCap[KdNode[T]](len(tree))

    var stack: seq[KdNode[T]] = @[tree.root]
    while stack.len > 0:
        var n = stack.pop()
        if n != nil:
            nodes.add(newNode(n.point, n.data))

            stack.add(n.left)
            stack.add(n.right)

    tree.root = buildTree(nodes)
    tree.len = len(nodes)

proc nearestNeighbour*[T](tree: var KdTree[T], point: KdPoint): (KdPoint, T, float) =
    ## Returns the nearest neighbour of an input target point, the data associated with the nearest neighbour, and the distance
    ## between the target point and the nearest neighbour. Notice that the returned distance
    ## uses the distance metric based on the `distFunc` parameter when the tree is created. By default, and if
    ## unspecified, this metric is the squared distance.
    ## 
    ## .. code-block:: nim
    ##   let x = 100.0
    ##   let y = 25.0
    ##   let (pt, values, dist) = tree.nearestNeighbour([x, y])

    var 
        stack: seq[KdNode[T]] = @[tree.root]
        minDist: float = Inf
        dist: float
        diff: float
        split: int
        p1: array[K, float]
        p2: array[K, float]
    while stack.len > 0:
        var n = stack.pop()
        dist = tree.distFunc(point, n.point)
        if dist < minDist:
            minDist = dist
            result = (n.point, n.data, minDist)

        split = n.splitDimension
        if point[split] <= n.point[split]:
            if n.left != nil:
                stack.add(n.left)
            
            if n.right != nil:
                p1[0] = point[split]
                p2[0] = n.point[split]
                diff = tree.distFunc(p1, p2)
                # diff = point[split] - n.point[split]
                # if minDist > diff*diff:
                if minDist > diff:
                    stack.add(n.right)
            
        else:
            if n.right != nil:
                stack.add(n.right)
            
            if n.left != nil:
                p1[0] = point[split]
                p2[0] = n.point[split]
                diff = tree.distFunc(p1, p2)
                # diff = point[split] - n.point[split]
                # if minDist > diff*diff:
                if minDist > diff:
                    stack.add(n.left)

proc nearestNeighbours*[T](tree: var KdTree[T], point: KdPoint, numNeighbours: int): seq[(KdPoint, T, float)] =
    ## Returns a specified number (`numNeighbours`) of nearest neighbours of a target point (`point`). Each return point 
    ## is accompanied by the associated data, and the distance between the target and return points. Notice that the 
    ## returned distance uses the distance metric based on the `distFunc` parameter when the tree is created. By default, 
    ## and if unspecified, this metric is the squared distance.
    ## 
    ## .. code-block:: nim
    ##   let x = 100.0
    ##   let y = 25.0
    ##   let ret = tree.nearestNeighbours([x, y], numNeighbours=5)
    ##   for (pt, value, dist) in ret:
    ##     echo fmt"point={pt}, value={values}, dist={dist}"

    doAssert numNeighbours > 0, "The parameter `numNeighbours` must be larger than zero."

    if numNeighbours == 1:
        return @[nearestNeighbour(tree, point)]

    var 
        stack: seq[KdNode[T]] = @[tree.root]
        minDist: float = Inf
        dist: float
        diff: float
        split: int
        p1: array[K, float]
        p2: array[K, float]

    result = newSeqOfCap[(KdPoint, T, float)](numNeighbours)

    while stack.len > 0:
        var n = stack.pop()
        dist = tree.distFunc(point, n.point)
        if dist <= minDist or len(result) < numNeighbours:
            if len(result) == 0:
                result.add((n.point, n.data, dist))
            else:
                for a in 0..<numNeighbours:
                    if dist <= result[a][2]:
                        result.insert((n.point, n.data, dist), a)
                        if len(result) > numNeighbours:
                            discard result.pop()
                        break
                    elif a == high(result) and len(result) < numNeighbours:
                        result.add((n.point, n.data, dist))
                        break

            minDist = result[high(result)][2] # it's actually the largest min distance

        split = n.splitDimension
        if point[split] < n.point[split]:
            if n.left != nil:
                stack.add(n.left)
            
            if n.right != nil:
                # diff = point[split] - n.point[split]
                # if minDist > diff * diff:
                p1[0] = point[split]
                p2[0] = n.point[split]
                diff = tree.distFunc(p1, p2)
                if minDist > diff:
                    stack.add(n.right)
            
        else:
            if n.right != nil:
                stack.add(n.right)
            
            if n.left != nil:
                # diff = point[split] - n.point[split]
                # if minDist > diff * diff:
                p1[0] = point[split]
                p2[0] = n.point[split]
                diff = tree.distFunc(p1, p2)
                if minDist > diff:
                    stack.add(n.left)

proc withinRadius*[T](tree: var KdTree[T], point: KdPoint, radius: float, sortResults=false): seq[(KdPoint, T, float)] =
    ## Returns all of the points contained in the tree that are within a specified radius of a target point. By default, the
    ## returned points are in an arbitrary order, unless the `sortResults` parameter is set to true, in which case the return
    ## points will be sorted from nearest to farthest from the target. Notice that the returned distance uses the distance 
    ## metric based on the `distFunc` parameter when the tree is created. By default, and if unspecified, this metric is the 
    ## squared distance. Importantly, the `radius` parameter must be a distance measured using the same distance metric as
    ## specified by the `distFunc` parameter when the tree is created.
    ## 
    ## .. code-block:: nim
    ##   let x = 100.0
    ##   let y = 25.0
    ##   var ret = tree.withinRadius([x, y], radius=5.0, sortResults=true)
    ##   for (pt, value, dist) in ret:
    ##      echo fmt"point={pt}, value={value}, dist={dist}"

    var 
        stack: seq[KdNode[T]] = @[tree.root]
        dist: float
        split: int
        p1: array[K, float]
        p2: array[K, float]
        diff: float

    result = newSeq[(KdPoint, T, float)]()
    
    if radius <= 0:
        return result
    
    while stack.len > 0:
        var n = stack.pop()
        dist = tree.distFunc(point, n.point)
        if dist <= radius:
            result.add((n.point, n.data, dist))

        split = n.splitDimension
        if point[split] <= n.point[split]:
            if n.left != nil:
                stack.add(n.left)
            
            if n.right != nil:
                # if radius > abs(point[split] - n.point[split]):
                p1[0] = point[split]
                p2[0] = n.point[split]
                diff = tree.distFunc(p1, p2)
                if radius > diff:
                    stack.add(n.right)
            
        else:
            if n.right != nil:
                stack.add(n.right)
            
            if n.left != nil:
                # if radius > abs(point[split] - n.point[split]):
                p1[0] = point[split]
                p2[0] = n.point[split]
                diff = tree.distFunc(p1, p2)
                if radius > diff:
                    stack.add(n.left)

    if len(result) == 0:
        return result

    if sortResults:
        proc kdNodeCmp(x, y: (KdPoint, T, float)): int =
                if x[2] < y[2]: -1
                elif x[2] == y[2]: 0
                else: 1

        result.sort(kdNodeCmp)

type HyperRectangle* = object
    ## A HyperRectangle is used by the withinRange search function to identify multi-deminsional ranges.
    min*: KdPoint
    max*: KdPoint

func newHyperRectangle*(min: KdPoint, max: KdPoint): HyperRectangle =
    ## Creates a new HyperRectangle
    #new(result)
    result.min = min
    result.max = max

func withinRange*[T](tree: var KdTree[T], rectangle: HyperRectangle): seq[(KdPoint, T)] =
    ## Returns all of the points contained in the tree that are within a target HyperRectangle. 
    ## 
    ## .. code-block:: nim
    ##   var 
    ##     min: array[2, float] = [0.0, 0.0]
    ##     max: array[2, float] = [100.0, 100.0]
    ##     hyperRect = newHyperRectangle(min, max)
    ##   
    ##   var ret = tree.withinRange(hyperRect)
    ##   for (pt, value) in ret:
    ##     echo fmt"point={pt}, value={value}"

    var 
        stack: seq[KdNode[T]] = @[tree.root]
        split: int
        withinRange: bool

    result = newSeq[(KdPoint, T)]()
    
    for i in 0..<K:
        if rectangle.max[i] <= rectangle.min[i]:
            # it's an ill-formed HyperRectangle
            return result
    
    while stack.len > 0:
        var n = stack.pop()
        withinRange = true
        for i in 0..<K:
            if n.point[i] < rectangle.min[i] or n.point[i] > rectangle.max[i]:
                withinRange = false
                break
        
        if withinRange:
            result.add((n.point, n.data))

        split = n.splitDimension
        if rectangle.min[split] <= n.point[split]:
            if n.left != nil:
                stack.add(n.left)
        
        if rectangle.max[split] >= n.point[split]:
            if n.right != nil:
                stack.add(n.right)

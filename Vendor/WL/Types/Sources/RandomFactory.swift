//
//  RandomFactory.swift
//  mcTypes-macOS
//
//  Created by Vlad Gorlov on 11.11.17.
//  Copyright © 2017 Demo. All rights reserved.
//

import Foundation
import CoreGraphics

/// - SeeAlso: [ How does one generate a random number in Apple's Swift language? - Stack Overflow ]
/// (http://stackoverflow.com/questions/24007129/how-does-one-generate-a-random-number-in-apples-swift-language)
public struct RandomFactory {

   public static func value(in range: ClosedRange<UInt32>) -> UInt32 {
      let upperBound = (range.upperBound - range.lowerBound)
      let randomNumber = arc4random_uniform(upperBound)
      return range.lowerBound + randomNumber
   }

   public static func value<T: FloatingPoint>(in range: ClosedRange<T>) -> T {
      var randomValue: UInt32 = 0
      arc4random_buf(&randomValue, MemoryLayout<UInt32>.size)
      let randomValueFloat = T(randomValue) / T(UInt32.max)
      return (randomValueFloat * (range.upperBound - range.lowerBound)) + range.lowerBound
   }

   public static func point(rangeX: ClosedRange<CGFloat>, rangeY: ClosedRange<CGFloat>) -> CGPoint {
      let x = value(in: rangeX)
      let y = value(in: rangeY)
      return CGPoint(x: x, y: y)
   }

   public static func point(x: CGFloat, rangeY: ClosedRange<CGFloat>) -> CGPoint {
      let y = value(in: rangeY)
      return CGPoint(x: x, y: y)
   }

   public static func point(rangeX: ClosedRange<CGFloat>, y: CGFloat) -> CGPoint {
      let x = value(in: rangeX)
      return CGPoint(x: x, y: y)
   }
}

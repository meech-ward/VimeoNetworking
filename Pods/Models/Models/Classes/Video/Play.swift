//
//  Play.swift
//  Videos
//
//  Created by King, Gavin on 2/6/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//

import Foundation

public struct Play: Model
{
    public let progressive: [ProgressiveFile]?
    public let hls: [HLSFile]?
    public let status: PlayStatus?
}

extension Play
{
    public enum PlayStatus: String, Codable
    {
        case playable
        case purchaseRequired = "purchase_required"
        case restricted
        case unavailable
    }
}
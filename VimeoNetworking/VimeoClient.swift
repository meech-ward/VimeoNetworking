//
//  VimeoClient.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/21/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

final class VimeoClient
{
    // MARK: - 
    
    enum Method: String
    {
        case GET
        case POST
        case PUT
        case PATCH
        case DELETE
    }
    
    typealias RequestParameters = [String: String]
    
    static let ErrorDomain = "VimeoClientErrorDomain"
    
    // TODO: make these an enum [RH] (3/30/16)
    static let ErrorInvalidDictionary = 1001
    static let ErrorNoMappingClass = 1002
    static let ErrorMappingFailed = 1003
    
    // MARK: -
    
    private let sessionManager: VimeoSessionManager
    
    init(sessionManager: VimeoSessionManager)
    {
        self.sessionManager = sessionManager
    }
    
    // MARK: - Authentication
    
    var authenticatedAccount: VIMAccountNew?
    {
        didSet
        {
            if let authenticatedAccount = self.authenticatedAccount
            {
                self.sessionManager.clientDidAuthenticateWithAccount(authenticatedAccount)
            }
            else
            {
                self.sessionManager.clientDidClearAccount()
            }
        }
    }
    
    var authenticatedUser: VIMUser?
    {
        return self.authenticatedAccount?.user
    }
    var isAuthenticated: Bool
    {
        return self.authenticatedAccount?.isAuthenticated() ?? false
    }
    var isAuthenticatedWithUser: Bool
    {
        return self.authenticatedAccount?.isAuthenticatedWithUser() ?? false
    }
    var isAuthenticatedWithClientCredentials: Bool
    {
        return self.authenticatedAccount?.isAuthenticatedWithClientCredentials() ?? false
    }
    
    // MARK: - Request
    
    // TODO: specify completion queue [RH] (3/30/16)
    func request<ModelType where ModelType: MappableResponse>(request: Request<ModelType>, completion: ResultCompletion<ModelType>.T)
    {
        let urlString = request.path
        let parameters = request.parameters
        
        let success: (NSURLSessionDataTask, AnyObject?) -> Void = { (task, responseObject) in
            self.handleRequestSuccess(request: request, task: task, responseObject: responseObject, completion: completion)
        }
        
        let failure: (NSURLSessionDataTask?, NSError) -> Void = { (task, error) in
            self.handleRequestFailure(request: request, task: task, error: error, completion: completion)
        }
        
        switch request.method
        {
        case .GET:
            self.sessionManager.GET(urlString, parameters: parameters, success: success, failure: failure)
        case .POST:
            self.sessionManager.POST(urlString, parameters: parameters, success: success, failure: failure)
        case .PUT:
            self.sessionManager.PUT(urlString, parameters: parameters, success: success, failure: failure)
        case .PATCH:
            self.sessionManager.PATCH(urlString, parameters: parameters, success: success, failure: failure)
        case .DELETE:
            self.sessionManager.DELETE(urlString, parameters: parameters, success: success, failure: failure)
        }
    }
    
    private func handleRequestSuccess<ModelType where ModelType: MappableResponse>(request request: Request<ModelType>, task: NSURLSessionDataTask, responseObject: AnyObject?, completion: ResultCompletion<ModelType>.T)
    {
        // TODO: How do we handle responses where a nil 200 response is fine and expected, like watchlater? [RH] (3/30/16)
        guard let responseDictionary = responseObject as? [String: AnyObject]
        else
        {
            let description = "VimeoClient requestSuccess returned invalid/absent dictionary"
            
            assertionFailure(description)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: self.dynamicType.ErrorInvalidDictionary, userInfo: [NSLocalizedDescriptionKey: description])
            
            self.handleRequestFailure(request: request, task: task, error: error, completion: completion)
            
            return
        }
        
        // Deserialize the dictionary into a model object
        
        guard let mappingClass = ModelType.mappingClass
        else
        {
            let description = "VimeoClient no mapping class found"
            
            assertionFailure(description)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: self.dynamicType.ErrorNoMappingClass, userInfo: [NSLocalizedDescriptionKey: description])
            
            self.handleRequestFailure(request: request, task: task, error: error, completion: completion)
            
            return
        }
        
        let objectMapper = VIMObjectMapper()
        let modelKeyPath = request.modelKeyPath ?? ModelType.modelKeyPath
        objectMapper.addMappingClass(mappingClass, forKeypath: modelKeyPath ?? "")
        var mappedObject = objectMapper.applyMappingToJSON(responseDictionary)
        
        if let modelKeyPath = modelKeyPath
        {
            mappedObject = (mappedObject as? [String: AnyObject])?[modelKeyPath]
        }
        
        guard let modelObject = mappedObject as? ModelType
        else
        {
            let description = "VimeoClient couldn't map to ModelType"
            
            assertionFailure(description)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: self.dynamicType.ErrorMappingFailed, userInfo: [NSLocalizedDescriptionKey: description])
            
            self.handleRequestFailure(request: request, task: task, error: error, completion: completion)
            
            return
        }
        
        completion(result: .Success(result: modelObject))
    }
    
    private func handleRequestFailure<ModelType where ModelType: MappableResponse>(request request: Request<ModelType>, task: NSURLSessionDataTask?, error: NSError, completion: ResultCompletion<ModelType>.T)
    {
        // TODO: Intercept errors globally [RH] (3/29/16)
        
        completion(result: .Failure(error: error))
    }
}
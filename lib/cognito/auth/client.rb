module Cognito
  module Auth
    module Client
      
      def client
        @client ||= Aws::CognitoIdentityProvider::Client.new(
          region: configuration.user_pool_region
        )
      end

      def pool_description
        Cognito::Auth.client.describe_user_pool(
          user_pool_id: Cognito::Auth.configuration.user_pool_id
        ).user_pool
      end

      def schema_attributes
        aws_object_array_to_hash(pool_description.schema_attributes)
      end

      def client_description
        Cognito::Auth.client.describe_user_pool_client(
          user_pool_id: Cognito::Auth.configuration.user_pool_id,
          client_id: Cognito::Auth.configuration.client_id
        ).user_pool_client
      end

      def write_attributes
        client_description.write_attributes
      end

      def read_attributes
        client_description.read_attributes
      end
    end
  end
end

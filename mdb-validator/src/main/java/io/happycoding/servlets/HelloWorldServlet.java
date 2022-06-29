package io.happycoding.servlets;

import java.io.IOException;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import static com.mongodb.client.model.Filters.eq;
import org.bson.Document;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.MongoIterable;


@WebServlet("/movie/*")
public class HelloWorldServlet extends HttpServlet {

  @Override
  public void doGet(HttpServletRequest request, HttpServletResponse response)
      throws IOException {
    String pathInfo = request.getPathInfo();
    String dbUri = System.getenv("DB_URI");
    if(dbUri == null || dbUri.length() == 0) {
      response.setContentType("text/html;");
      response.getWriter().println("<h2>DB_URI environment variable unset</h2>");
      return;
    }
    if(pathInfo != null && pathInfo.length()>1) {
      response.setContentType("text/json;");
      String movieTitle = pathInfo.substring(1, pathInfo.length());
      try (MongoClient mongoClient = MongoClients.create(dbUri)) {
        
        MongoDatabase database = mongoClient.getDatabase("sample_mflix");
        MongoCollection<Document> collection = database.getCollection("movies");
        Document doc = collection.find(eq("title", movieTitle)).first();
        response.getWriter().println(doc.toJson());
      } catch (Exception e) {
        response.getWriter().println(e.getMessage());
        e.printStackTrace();
      }
    } else {
      try (MongoClient mongoClient = MongoClients.create(dbUri)) {
        response.setContentType("text/html;");
        MongoIterable<String> dbNames = mongoClient.listDatabaseNames();
        response.getWriter().println("<ul>");
        for (String dbName : dbNames) {
          response.getWriter().println("<li>" + dbName + "</li>");
        }
        response.getWriter().println("</ul>");
      } catch (Exception e) {
        response.getWriter().println(e.getMessage());
        e.printStackTrace();
      }
    }
  }
}
